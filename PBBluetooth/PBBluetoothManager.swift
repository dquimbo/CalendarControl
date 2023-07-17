//
//  PBBluetoothManager.swift
//  PBNetworking
//
//  Created by Jon Vogel on 8/12/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import CoreMotion
import Combine
import CoreLocation
import CoreBluetooth

/// `PBBluetoothManager` provides a simple, high-level interface for interacting with Pebblebee devices.
public class PBBluetoothManager: NSObject {
    
    // MARK: - Initialization
    
    public static let shared = PBBluetoothManager()
    
    private override init() {
        super.init()
        
        locationManager.delegate = self
        
        outOfRangeTimer = Timer.scheduledTimer(timeInterval: self.outOfRangeCheckInterval, target: self, selector: #selector(self.updateDevices(timer:)), userInfo: nil, repeats: true)

        configureRegionMonitoring()
        
        PBBroadcastManager.shared.requestAuthorization(withQueue: nil)
    }
    
    internal let advertisementReceivedPassthrough: PassthroughSubject<PBDevice, Never> = PassthroughSubject<PBDevice, Never>()
    
    // MARK: - Public Variables
    
    /// Returns the current state of the Bluetooth scanner
    public private(set) var isScanningEnabled = false {
        didSet {
            if isScanningEnabled {
                if self.centralManager == nil {
                    // Initialize Central Manager
                    self.centralManager = CBCentralManager(delegate: self, queue: nil, options:[CBCentralManagerScanOptionAllowDuplicatesKey: true, CBCentralManagerOptionShowPowerAlertKey: true])
                }
                self.centralManager?.scanForPeripherals(withServices: self.servicesToScannFor, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true, CBCentralManagerOptionShowPowerAlertKey: true])
            } else {
                self.centralManager?.stopScan()
            }
        }
    }
    
    /// Current value of the Bluetooth connectivity
    public private(set) var bluetoothState: CurrentValueSubject<PBBluetoothCentralStatus, Never> = CurrentValueSubject<PBBluetoothCentralStatus, Never>(.Unavailable)
    
    /// The set of `PBDevice`s that the bluetooth has scanned. This gets auto populated with new `PBDevice`s as the manager sees them.
    public private(set) var devices = Set<PBDevice>()
    
    /// This publisher emits when the scanner received an advertisement from the device and after the info was updated
    public var advertisementReceivedPublisher: AnyPublisher<PBDevice, Never> {
        advertisementReceivedPassthrough.eraseToAnyPublisher()
    }
    
    // MARK: - Public Methods
    
    /// Starts the Bluetooth scanner
    public func startScanning() {
        isScanningEnabled = true
        
        if failedRegionAttempts > 2 {
            failedRegionAttempts = 0
            configureRegionMonitoring()
        }
    }
    
    /// Stops the Bluetooth scanner
    public func stopScanning() {
        isScanningEnabled = false
    }
    
    /// Removes a device from the list of scanned devices
    /// - Parameter macAddress: The MAC address of the devices that will be removed
    public func removeDevice(macAddress: String) {
        isScanningEnabled = false
        devices = devices.filter({ $0.macAddress != macAddress })
        isScanningEnabled = true
    }
    
    /// Removes all the devices from the list of scanned devices
    public func removeAllDevices() {
        isScanningEnabled = false
        devices.removeAll()
        isScanningEnabled = true
    }
    
    // MARK: - Internal Methods
    
    /// Attempts to connect the PBDevice
    /// - Parameters:
    ///   - device: the PBDevice to be connected
    ///   - completion: the completion handler will return nil on success or PBBluetoothError on failure
    internal func connectDevice(device: PBDevice, completion: ((_ connectionError: PBBluetoothError?) -> Void)?) {
        guard bluetoothState.value == .Authorized else {
            completion?(.bluetoothUnauthorized)
            return
        }
        
        if let p = device.peripheral {
            connectionCompletionHandlers[p.identifier] = completion
            
            self.centralManager?.connect(p, options: nil)
            
            device.connectionStatePassthrough.send(.connecting)
        } else {
            completion?(.couldntDetermineDeviceState)
        }
    }
    
    
    /// Attemps to disconnect the PBDevice
    /// - Parameters:
    ///   - device: the PBDevice to be disconnected
    ///   - completion: the completion handler will return nil on success or PBBluetoothError on failure
    internal func disconnectDevice(device: PBDevice, completion: @escaping (_ disconnectionError: PBBluetoothError?) -> Void) {
        guard bluetoothState.value == .Authorized else {
            completion(.bluetoothUnauthorized)
            return
        }
        
        if let p = device.peripheral {
            if p.state != .connected || p.state != .connecting {
                self.disconnectionCompletionHandlers[p.identifier] = completion
                
                self.centralManager?.cancelPeripheralConnection(p)
                
                device.connectionStatePassthrough.send(.disconnecting)
            } else {
                completion(.couldntDetermineDeviceState)
            }
        } else {
            completion(.couldntDetermineDeviceState)
        }
    }
    
    // TODO: REMOVE
    /// Enable or disable location updates, including when the app in running in the background. Your app must register for location updates via its required background modes before enabling location updates.
    @objc public var locationUpdatesEnabled = false {
        didSet {
            if locationUpdatesEnabled {
                if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .notDetermined {
                    locationManager.requestWhenInUseAuthorization()
                }
                
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                
                startPeriodicLocationUpdates()
            } else {
                stopPeriodicLocationUpdates()
            }
        }
    }
    
    // TODO: REMOVE
    @objc public var headingUpdatesEnabled = false {
        didSet {
            guard CLLocationManager.locationServicesEnabled() && (CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse) else {
                return
            }
            
            if headingUpdatesEnabled {
                locationManager.startUpdatingHeading()
                locationManager.startUpdatingLocation()
            } else {
                locationManager.stopUpdatingHeading()
                locationManager.stopUpdatingLocation()
            }
        }
    }
    
    // TODO: REMOVE
    /// The current status of the device manager's access to system location services. You will get notified through the `NotificationCenter` with the `PBLocationServiceStatusNotification` when this value changes.
    public internal(set) var locationServicesStatus = PBLocationServicesStatus.Unavailable {
        didSet {
            NotificationCenter.default.post(name: PBLocationServiceStatusNotification, object: self.locationServicesStatus)
        }
    }
    
    /// The set of MAC addresses that are auto-connected when in range
    var autoConnectingDevices: [String : AnyCancellable] = [:]
    
    var myLastLocation: PBLocationReading?
    
    //The array of service UUID's that the central manager will scann for.
    @objc let servicesToScannFor = [finderServiceUUID, r4kTagServiceUUID, smpServiceUUID, stoneServiceUUID, proprietaryDataServiceUUID, linkLossServiceUUID, immediateAlertServiceUUID, locationBeaconServiceUUID]
    //Core Location and Core Bluetooth managers
    @objc var centralManager: CBCentralManager?
    @objc var locationManager = CLLocationManager()
    //Timer that will check for out of range objects
    @objc var outOfRangeTimer: Timer?
    //Time interval for out of range timer checker
    @objc var outOfRangeCheckInterval: Double = 15
    //The watch dog timer to help us realize if we really shoud mark stuff out of range
    @objc var outOfRangeWatchDog: Date?
    
    @objc var failedRegionAttempts: Int = 0
    
    @objc var scanCounter: Int = 0
    
    @objc var pendingCallTimer: Timer?
    
    private var periodicLocationUpdateTimer: Timer?
    private var locationTimerPostponedCount: Int = 0
    
    /// Request always allow location services
    public func requestAllowAlwaysLocationServices() {
        locationManager.requestAlwaysAuthorization()
    }

    /// Function that quickly starts and stops scanning in the Core Bluetooth manager
    ///
    /// - Parameter sender: An objects that calls this function
    @objc public func resetScan( _ sender: AnyObject) {
        if isScanningEnabled {
            isScanningEnabled = false
            isScanningEnabled = true
        }
    }
    
    //MARK: Out of Range Control
    @objc func updateDevices(timer: Timer) {
        guard bluetoothState.value == .Authorized else { return }
        
        self.resetScan(self)
        
        // Julian's temporary note: I understand that if we couldn't update in the last minute (phone off or app closed?) we should mark everything as out of range WITHOUT a notification and return.
        if let out = self.outOfRangeWatchDog {
            let timeIntervalSinceLastUpdate = Date().timeIntervalSince(out)
            
            guard timeIntervalSinceLastUpdate <= 1200 else {
                self.outOfRangeWatchDog = Date()
                
                for device in self.devices {
                    device.mark(inRange: false, notify: false)
                }
                
                return
            }
        }
        
        self.outOfRangeWatchDog = Date()
        
        // We mark every connected device as IN RANGE
        for device in devices where device.peripheral?.state == .connected && device is PBDeviceAutoConnectable {
            device.mark(inRange: true, notify: true)
        }

        // We filter by all the IN RANGE devices and will check how long has been since we saw them...
        let inRangeDevices = self.devices.filter { (aDevice) -> Bool in
            return aDevice.isInRange
        }
        
        for deviceToUpdate in inRangeDevices {
            if let lastTimeSeen = deviceToUpdate.lastSeenTime {
                let timeInterval = Date().timeIntervalSince(lastTimeSeen)
                
                let timedOut = timeInterval > deviceToUpdate.refreshRateInternal
                
                if deviceToUpdate.connectionState == .connected, deviceToUpdate is PBDeviceAutoConnectable {
                    // Since the device will always be connected when in range, we need to generate a reading on this timer, instead of the RSSI method
                    deviceToUpdate.lastSeenTime = Date()
                    
                    advertisementReceivedPassthrough.send(deviceToUpdate)
                } else if timedOut && deviceToUpdate.connectionState != .connected {
                    if let myLastLocation = myLastLocation?.location,
                       let deviceLastLocation = deviceToUpdate.lastLocation,
                       myLastLocation.distance(from: deviceLastLocation) < 150 {
                        continue
                    } else {
                        // Fire notification
                        deviceToUpdate.mark(inRange: false, notify: true)
                    }
                }
            }
        }
    }
    
    
    @objc public func configureRegionMonitoring(deviceMACtoMonitor: [String] = [String]()) {
        pendingCallTimer?.invalidate()
        pendingCallTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { pendingCallTimer in
            self.configureRegionMonitoringCall(deviceMACtoMonitor: deviceMACtoMonitor)
        }
    }
    
    //MARK: Region Monitoring Control
    @objc public func configureRegionMonitoringCall(deviceMACtoMonitor: [String] = [String]()) {
        
        var majorMinorCombos: [(major: Int, minor: Int)] = [(major: Int, minor: Int)]()
        
        var monitoredMajorMinorCombos: [(major: Int, minor: Int)] = [(major: Int, minor: Int)]()
        
        for i in deviceMACtoMonitor{
            if (i.count > 11) {
                let fromIndex = i.index(i.startIndex, offsetBy: 4)
                let toIndex = i.index(i.startIndex, offsetBy: 7)
                
                let majorSubdata = i[fromIndex...toIndex]
                
                let fromIndexMinor = i.index(i.startIndex, offsetBy: 8)
                let toIndexMinor = i.index(i.startIndex, offsetBy: 11)

                let minorSubdata = i[fromIndexMinor...toIndexMinor]
                let majorSubdataInt = UInt16(majorSubdata, radix: 16) ?? 0
                let minorSubdataInt = UInt16(minorSubdata, radix: 16) ?? 0
                
                majorMinorCombos.append((major: Int(majorSubdataInt), minor: Int(minorSubdataInt)))
            }
        }
        
        var needToMonitorStoneTracking = true
        var needToMonitorFinderTracking = true
        //Variable that will be used to check if we are Monitoring for the Interrupt UUID
        var needToMonitorInterrupt = true
        //Loop through the monitored regions to see if we will need to register them for monitoring
        for monitoredRegion in self.locationManager.monitoredRegions as! Set<CLBeaconRegion> {
            switch monitoredRegion.proximityUUID.uuidString {
            case stoneTrackingRegionUUID.uuidString:
                needToMonitorStoneTracking = false
                self.locationManager.requestState(for: monitoredRegion)
            case finderTrackingRegionUUID.uuidString:
                needToMonitorFinderTracking = false
                self.locationManager.requestState(for: monitoredRegion)
            case motionRegionUUID.uuidString:
                //Get the major and Minor from this region
                if let monitoredMajor = monitoredRegion.major?.intValue, let monitoredMinor = monitoredRegion.minor?.intValue {
                    //Add them to the monitored Major and Minor COmbo array of tuples
                    monitoredMajorMinorCombos.append((major: monitoredMajor, minor: monitoredMinor))
                    self.locationManager.requestState(for: monitoredRegion)
                }
                break
            case inputEventRegionUUID.uuidString:
                needToMonitorInterrupt = false
                self.locationManager.requestState(for: monitoredRegion)
                break
            default:
                break
            }
        }
        
        for (_, v) in majorMinorCombos.enumerated() {
            for (j, u) in monitoredMajorMinorCombos.enumerated() {
                if v == u {
                    //  majorMinorCombos.remove(at:  majorMinorCombos.index(of: v))
                    if let index = majorMinorCombos.firstIndex(where: { $0 == v }) {
                        majorMinorCombos.remove(at: index)
                    }
                    
                    monitoredMajorMinorCombos.remove(at: j)
                }
            }
        }
        
        for r in majorMinorCombos {
            let newRegion = CLBeaconRegion(proximityUUID: motionRegionUUID, major: UInt16(r.major), minor: UInt16(r.minor), identifier: String(r.minor))
            self.locationManager.startMonitoring(for: newRegion)
        }
        
        for r in monitoredMajorMinorCombos {
            for region in self.locationManager.monitoredRegions as! Set<CLBeaconRegion> {
                if region.major?.intValue == r.major && region.minor?.intValue == r.minor {
                    self.locationManager.stopMonitoring(for: region)
                }
            }
        }
        
        if needToMonitorStoneTracking {
            let trackingRegion = CLBeaconRegion(proximityUUID: stoneTrackingRegionUUID, identifier: stoneTrackingRegionIdentitifer + "-" + UUID().uuidString)
            locationManager.startMonitoring(for: trackingRegion)
        }
        
        if needToMonitorFinderTracking {
            let trackingRegion = CLBeaconRegion(proximityUUID: finderTrackingRegionUUID, identifier: finderTrackingRegionIdentifier + "-" + UUID().uuidString)
            locationManager.startMonitoring(for: trackingRegion)
        }
        
        if needToMonitorInterrupt {
            let inputEventRegion = CLBeaconRegion(proximityUUID: inputEventRegionUUID, identifier: inputRegionIdentitifer + "-" + UUID().uuidString)
            locationManager.startMonitoring(for: inputEventRegion)
        }
    }
    
    // MARK: - Connecting and Disconnecting Pebblebee Devices
    // completion handlers for device connection / disconnection requests, stored by UUID of the backing peripheral
    var connectionCompletionHandlers: [UUID: (_ connectionError: PBBluetoothError?) -> Void] = [:]
    var disconnectionCompletionHandlers: [UUID: (_ disconnectionError: PBBluetoothError?) -> Void] = [:]
    
    /// MARK: Location updating
    /// Returns a `PBLocationReading` object that was constructed with a `CLLocationManager`'s `.location` property. According to Apples documentation this is a cached location and might not represend the actual location of the Apple device. However, this is easier on battery. This function will not append a fresh `PBLocationReading` to in range devices.
    ///
    /// - Returns: The `PBLocationReading` if we were able to get the cached location from the `CLLocationManager`
    public func getCachedLocation() -> PBLocationReading? {
        guard let loc = self.myLastLocation else {
            guard let localloc = self.locationManager.location else{
                return nil
            }
            
            let newLoc = PBLocationReading(withLocation: localloc)
            
            return newLoc
        }
        
        return loc
    }
}

// MARK: CBCentralManagerDelegate

extension PBBluetoothManager: CBCentralManagerDelegate {
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Updated observable state property
        if let deviceConnected = devices.filter({ $0.peripheral?.identifier == peripheral.identifier }).first {
            deviceConnected.connectionStatePassthrough.send(.connected)
        }
        
        if let completion = connectionCompletionHandlers[peripheral.identifier] {
            DispatchQueue.main.async {
                completion(nil)
            }
            connectionCompletionHandlers[peripheral.identifier] = nil
        }
    }
    
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Swift.Error?) {
        // Updated observable state property
        if let deviceNotConnected = devices.filter({ $0.peripheral?.identifier == peripheral.identifier }).first {
            deviceNotConnected.connectionStatePassthrough.send(.disconnected)
        }
        
        if let completion = connectionCompletionHandlers[peripheral.identifier] {
            DispatchQueue.main.async {
                completion(.couldntConnectDevice)
            }
            
            connectionCompletionHandlers[peripheral.identifier] = nil
        }
    }
    
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Swift.Error?) {
        // Updated observable state property
        if let deviceNotConnected = devices.filter({ $0.peripheral?.identifier == peripheral.identifier }).first {
            deviceNotConnected.connectionStatePassthrough.send(.disconnected)
        }
        
        if let completion = disconnectionCompletionHandlers[peripheral.identifier] {
            DispatchQueue.main.async {
                completion(error == nil ? nil : .couldntDetermineDeviceState)
            }
            connectionCompletionHandlers[peripheral.identifier] = nil
        }
    }
    

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Filter by Pebblebee services
        guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
              (serviceUUIDs.contains(finderServiceUUID) || serviceUUIDs.contains(linkLossServiceUUID) || serviceUUIDs.contains(immediateAlertServiceUUID) || serviceUUIDs.contains(r4kTagServiceUUID)),
              let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
                  return
              }
        
        if let productInfo = PBDevice.getDeviceInfo(fromData: advertisementData) {
            // The device already exists
            if let device = self.devices.first(where: {$0.macAddress == productInfo.0}) {
                device.dataParser.update(withAdvertisement: advertisementData, manufacturerData: manufacturerData, device: device)
                device.addPeripheral(thePeripheral: peripheral)
                
                if self.containsAutoConnectDevice(macAddress: device.macAddress) {
                    self.resetAutoConnectObserver(device: device)
                }
            
                advertisementReceivedPassthrough.send(device)
            // The device has to be created
            } else if let device = PBDevice.constructDevice(advertisementData: advertisementData, serviceUUIDs, peripheral: peripheral) {
                device.dataParser.update(withAdvertisement: advertisementData, manufacturerData: manufacturerData, device: device)
                device.addPeripheral(thePeripheral: peripheral)
                
                self.devices.insert(device)
                
                if let loc = self.locationManager.location {
                    let firstLoc = PBLocationReading(withLocation: loc)
                    device.locationHistory.append(firstLoc)
                }
                
                advertisementReceivedPassthrough.send(device)
            }
        }
    }
    
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            bluetoothState.send(.Unavailable)
        case .poweredOn:
            bluetoothState.send(.Authorized)
            
            if isScanningEnabled {
                centralManager?.scanForPeripherals(withServices: self.servicesToScannFor, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            }
        case .unauthorized:
            bluetoothState.send(.Unauthorized)
        case .unknown, .resetting, .unsupported:
            bluetoothState.send(.Other)
        @unknown default:
            bluetoothState.send(.Other)
        }
    }
    
}

// MARK: - CLLocationManagerDelegate

extension PBBluetoothManager: CLLocationManagerDelegate {
    
    @objc private func startPeriodicLocationUpdates() {
        guard periodicLocationUpdateTimer == nil else { return }
        
        let motionManager = CMMotionManager()
        let motionActivityManager = CMMotionActivityManager()
        
        let timeInterval: TimeInterval = CMMotionActivityManager.authorizationStatus() == .authorized && motionManager.isDeviceMotionAvailable ? 90 : 150
        
        periodicLocationUpdateTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: {[weak self] (_) in
            guard let `self` = self else { return }
            
            guard self.locationTimerPostponedCount < 6 else {
                self.locationTimerPostponedCount = 0
                
                self.locationManager.requestLocation()
                
                return
            }
            
            guard CMMotionActivityManager.authorizationStatus() == .authorized, motionManager.isDeviceMotionAvailable else {
                self.locationManager.requestLocation()
                
                return
            }
            
            motionActivityManager.queryActivityStarting(from: Date().addingTimeInterval(-1 * timeInterval), to: Date(), to: .main) { activities, error in
                guard let activities = activities else {
                    self.locationManager.requestLocation()
                    
                    return
                }
                
                let nonStationaryActivity = activities.first { !$0.stationary }
                
                if nonStationaryActivity != nil {
                    self.locationManager.requestLocation()
                } else {
                    self.locationTimerPostponedCount += 1
                }
            }
        })
        
        periodicLocationUpdateTimer?.fire()
    }
    
    @objc private func stopPeriodicLocationUpdates() {
        periodicLocationUpdateTimer?.invalidate()
        periodicLocationUpdateTimer = nil
    }
    
    // MARK: Core Locaiton delegate methods
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else{
            return
        }
        
        let locationReading = PBLocationReading(withLocation: loc)
        
        self.myLastLocation = locationReading
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: PBLocationUpdateNotification, object: locationReading)
        }
        
        var addresses = [String]()
        
        let inRangeDevices = self.devices.filter({ (aDevice) -> Bool in
            return Int(aDevice.lastSeenTime.timeIntervalSinceNow) > -70 && aDevice.isInRange == true
        })
        
        for device in devices where device.peripheral?.state == .connected {
            device.locationHistory.append(locationReading)
        }
    
        for device in inRangeDevices {
            if !device.locationHistory.contains(locationReading) {
                device.locationHistory.append(locationReading)
                
                if let macAddress = device.macAddress {
                    addresses.append(macAddress)
                }else{
                    addresses.append("Unknown Mac Address")
                }
            }
        }
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let _ = region as? CLBeaconRegion else {
            self.locationManager.stopMonitoring(for: region)
            return
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if bluetoothState.value == .Authorized && self.locationServicesStatus == .Authorized {
            guard let r = region else {
                return
            }
            self.locationManager.stopMonitoring(for: r)
            failedRegionAttempts += 1
            //why failing for finder tracking? Maybe uninstall?
            if(self.failedRegionAttempts < 2){
                self.configureRegionMonitoring()
            }
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: PBMonitoringDidFailNotification, object: error)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: PBLocationDidFailNotification, object: error)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: PBHeadingUpdateNotification, object: newHeading)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if CLLocationManager.locationServicesEnabled() {
            switch status {
            case .notDetermined:
                locationServicesStatus = .Unauthorized
            case .restricted:
                locationServicesStatus = .Unauthorized
            case .denied:
                locationServicesStatus = .Unauthorized
            case .authorizedAlways, .authorizedWhenInUse:
                locationServicesStatus = .Authorized
                
                if headingUpdatesEnabled {
                    stopPeriodicLocationUpdates()
                    
                    locationManager.startUpdatingHeading()
                    locationManager.startUpdatingLocation()
                } else {
                    startPeriodicLocationUpdates()
                    
                    locationManager.stopUpdatingHeading()
                    locationManager.stopUpdatingLocation()
                }
            @unknown default:
                locationServicesStatus = .Unauthorized
            }
        } else {
            locationServicesStatus = .Unavailable
        }
    }

}

// MARK: - AutoConnectedDevices

extension PBBluetoothManager: AutoConnectedDevices {
    
    private func resetAutoConnectObserver(device: PBDevice) {
        guard let autoConnectDevice = device as? PBDeviceAutoConnectable else {
            return
        }
        
        if autoConnectingDevices.keys.contains(device.macAddress) {
            autoConnectingDevices[device.macAddress]?.cancel()
            autoConnectingDevices.removeValue(forKey: device.macAddress)
        }
        
        let cancellable = device.connectionStatePublisher.sink { status in
            switch status {
            case .disconnected:
                autoConnectDevice.attemptToReconnect()
            default:
                break
            }
        }
        
        autoConnectingDevices[device.macAddress] = cancellable
        
        if device.connectionState != .connected {
            autoConnectDevice.attemptToReconnect()
        }
    }
    
    public func addAutoConnectDevice(macAddress: String) {
        if let device = devices.first(where: {$0.macAddress == macAddress}) {
            self.resetAutoConnectObserver(device: device)
        }
    }
    
    public func removeAutoConnectDevice(macAddress: String) {
        autoConnectingDevices[macAddress]?.cancel()
        autoConnectingDevices.removeValue(forKey: macAddress)
        
        if let device = devices.first(where: {$0.macAddress == macAddress}) {
            disconnectDevice(device: device, completion: { _ in })
        }
    }
    
    public func getAutoConnectDevices() -> [String] {
        return autoConnectingDevices.keys.sorted()
    }
    
    public func containsAutoConnectDevice(macAddress: String) -> Bool {
        return autoConnectingDevices.keys.contains(macAddress)
    }
    
    public func removeAllAutoConnectDevices() {
        for macAddress in getAutoConnectDevices() {
            removeAutoConnectDevice(macAddress: macAddress)
        }
    }
}

enum Bit: UInt8, CustomStringConvertible {
    case zero, one

    var description: String {
        switch self {
        case .one:
            return "1"
        case .zero:
            return "0"
        }
    }
}

func bits<T: FixedWidthInteger>(fromBytes bytes: T) -> [Bit] {
    // Make variable
    var bytes = bytes
    // Fill an array of bits with zeros to the fixed width integer length
    var bits = [Bit](repeating: .zero, count: T.bitWidth)
    // Run through each bit (LSB first)
    for i in 0..<T.bitWidth {
        let currentBit = bytes & 0x01
        if currentBit != 0 {
            bits[i] = .one
        }

        bytes >>= 1
    }

    return bits
}

extension FixedWidthInteger {
    var bits: [Bit] {
        // Make variable
        var bytes = self
        // Fill an array of bits with zeros to the fixed width integer length
        var bits = [Bit](repeating: .zero, count: self.bitWidth)
        // Run through each bit (LSB first)
        for i in 0..<self.bitWidth {
            let currentBit = bytes & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }

            bytes >>= 1
        }

        return bits
    }
}

