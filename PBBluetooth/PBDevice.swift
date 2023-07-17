//
//  PBDevice.swift
//  PBNetworking
//
//  Created by Jon Vogel on 7/27/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//


import CoreBluetooth
import CoreLocation
import Foundation
import Combine

/// Base class for objects representing Pebblebee Bluetooth devices. The device can store user-assigned data and report attribute updates to its delegate.
public class PBDevice: NSObject {
    
    //MARK: Public variables
    
    /// A brief text description given to the device, like "Car keys" or "Jon's Finder".
    public internal(set) var name: String?
    
    /// A unique identifier (currently the MAC address for every Pebblebee device) in `String` format.
    public internal(set) var macAddress: String!
    
    /// The system generated date that the 'PBDevice' was last scanned by the systems bluetooth hardware
    public internal(set) var lastSeenTime: Date!
    
    /// Lets us know if the device is currently in range, or was in range when the app was last launched.
    public internal(set) var isInRange = false
    
    /// Type of Pebblebee device this object is representing. Subclases should override this
    public var deviceType: PBDeviceType = .unknown
    
    ///The latest battery percentage gotten from a reading
    public internal(set) var batteryPercentage: Double? {
        didSet {
            guard let newValue = batteryPercentage else { return }
            
            guard let oldPercentage = oldValue else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: PBBatteryStateNotification, object: self)
                }
                
                return
            }
            
            if abs(oldPercentage - newValue) > 5 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: PBBatteryStateNotification, object: self)
                }
            }
        }
    }
    
    /// The current connection state of the device.
    public var connectionState: CBPeripheralState? {
        return self.peripheral?.state
    }
    
    /// Observable variable from Combine for getting notifications of CBPeripheralState changes
    public var connectionStatePublisher: AnyPublisher<CBPeripheralState, Never> {
        connectionStatePassthrough.eraseToAnyPublisher()
    }
    
    /// Observable variable from Combine for getting notifications of RSSI signals
    public var rssiPublisher: AnyPublisher<NSNumber, Never> {
        rssiPassthrough.eraseToAnyPublisher()
    }
    
    /// Represents the state of the button on a 'PBDevice'. You can get notifications about changes to this property through the 'PBButtonStateChangeNotification'
    public internal(set) var buttonState: PBButtonState = PBButtonState.none {
        didSet{
            guard buttonState != oldValue else { return }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: PBButtonStateChangeNotification, object: self)
            }
        }
    }
    
    // MARK: - Internal variables
    
    internal let connectionStatePassthrough: PassthroughSubject<CBPeripheralState, Never> = PassthroughSubject<CBPeripheralState, Never>()
    
    internal let rssiPassthrough: PassthroughSubject<NSNumber, Never> = PassthroughSubject<NSNumber, Never>()
    
    /// The parser of the advertisement data, to update the device attributes
    internal var dataParser: PBAdvertisementParser!
    
    /// This represents the refresh rate we use to broadcast the updates. We wait this amount of seconds before *attempting* (Smart Mode check will take place too) to fire a Left Behind alert.
    internal var refreshRateInternal: TimeInterval {
        return 615
    }
    
    /// Peripheral from CoreBluetooth
    internal private(set) var peripheral: CBPeripheral?
    
    // MARK: Initalizer
    
    @objc internal init(withMacAddress address: String) {
        super.init()
        
        self.macAddress = address
        self.lastSeenTime = Date()
        self.dataParser = PBAdvertisementParser()
    }
    
    // MARK: - Public Functions
    
    /// Connects the device
    /// - Parameter completion: The completion block returns nil on success and PBBluetoothError on error
    public func connect(completion: ((_ connectionError: PBBluetoothError?) -> Void)?) {
        PBBluetoothManager.shared.connectDevice(device: self, completion: completion)
    }
    
    /// Disconnects the device
    /// - Parameter completion: The completion block returns nil on success and PBBluetoothError on error
    public func disconnect(completion: @escaping (_ disconnectionError: PBBluetoothError?) -> Void) {
        PBBluetoothManager.shared.disconnectDevice(device: self, completion: completion)
    }
    
    /// Function needed for Hashable Protocol
    /// - Parameters:
    ///   - lhs: left operator PBDevice
    ///   - rhs: right operator PBDevice
    /// - Returns: true if equal
    public static func == (lhs: PBDevice, rhs: PBDevice) -> Bool {
        return lhs.macAddress == rhs.macAddress
    }
    
    // MARK: - Internal functions
    
    /// Updates the peripheral of this PBDevice
    /// - Parameter p: the new peripheral
    internal func addPeripheral(thePeripheral p: CBPeripheral) {
        if self.peripheral == p {
            return
        }else{
            self.peripheral = p
            self.peripheral?.delegate = self
        }
    }
    
    /// Marks the device in or out of range
    /// - Parameters:
    ///   - isInRange: A bool indicating whether it is in range or not
    ///   - notify: A bool indicating if a notification should sent across the system
    internal func mark(inRange isInRange: Bool, notify: Bool) {
        let sameAsPreviousValue = self.isInRange == isInRange
        
        self.isInRange = isInRange
        
        if notify && !sameAsPreviousValue {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: isInRange ? PBDeviceDidBecomeReachableNotification : PBDeviceDidBecomeUnreachableNotification, object: self)
            }
        }
    }
    
    /// Starts the discovery sequence for characteristics and services. This will not do anything if the device is not connected. Call this when a connection request for a device has returned with out an error.
    internal func discoverServices() {
        self.peripheral?.discoverServices(nil)
    }
    
    // MARK: - LOCATION STUFF TO BE REMOVED FROM SDK
    
    ///The last locaiton of this device
    @objc public var lastLocation: CLLocation? {
        return self.locationHistory.last?.location
    }
    
    ///The location history of this device. Will never contain duplicate locations as hashed by the sum of the latitude, longitude, and time stamp in seconds. Will never contain more than 100 values.
    public internal(set) var locationHistory: [PBLocationReading] = [PBLocationReading]() {
        didSet{
            if self.locationHistory.count > 100 {
                self.locationHistory.removeFirst()
            }
        }
    }
}

// MARK: - CBPeripheralDelegate

extension PBDevice: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            return
        }
        
        rssiPassthrough.send(RSSI)
    }
    
}

// MARK: - Class functions to construct devices

extension PBDevice {
    
    internal class func constructDevice(advertisementData: [String : Any], _ services: [CBUUID], peripheral: CBPeripheral) -> PBDevice? {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, manufacturerData.count > 6 else {
            return nil
        }
        
        guard let info = PBDevice.getDeviceInfo(fromData: advertisementData) else {
            return nil
        }
        
        let macAddress = info.0
        let type = info.1
        
        switch type {
        case .honey:
            return PBHoney(withMacAddress: macAddress)
        case .finder:
            guard services.contains(finderServiceUUID),
                  let majorMinor = PBFinder1.getMajorMinor(fromData: manufacturerData) else { return nil }
            
            return PBFinder1(withAMacAddress: macAddress, andMajor: majorMinor.0, andMinor: majorMinor.1)
        case .finder2:
            guard services.contains(finderServiceUUID),
                  let majorMinor = PBFinder2.getMajorMinor(fromData: manufacturerData) else { return nil }
            
            return PBFinder2(withAMacAddress: macAddress, andMajor: majorMinor.0, andMinor: majorMinor.1)
        case .card:
            guard services.contains(finderServiceUUID),
                  let majorMinor = PBCard.getMajorMinor(fromData: manufacturerData) else { return nil }
            
            return PBCard(withAMacAddress: macAddress, andMajor: majorMinor.0, andMinor: majorMinor.1)
        case .found:
            var cellularDevice: PBDevice
            
            guard let firmwareModelNumber = manufacturerData.last else { return nil }
            
            //Identify firmware
            if manufacturerData.count < 16 || firmwareModelNumber < 15 {
                guard let majorMinor = PBFoundRC.getMajorMinor(fromData: manufacturerData) else {
                    return nil
                }
                
                cellularDevice = PBFoundRC(withAMacAddress: macAddress, andMajor: majorMinor.0, andMinor: majorMinor.1)
            } else {
                guard let majorMinor = PBFound.getMajorMinor(fromData: manufacturerData) else {
                    return nil
                }
                
                cellularDevice = PBFound(withAMacAddress: macAddress, andMajor: majorMinor.0, andMinor: majorMinor.1)
            }
            
            return cellularDevice
        case .mfiCard:
            return PBMFiCard(withMacAddress: macAddress)
        case .mfiClip:
            return PBMFiClip(withMacAddress: macAddress)
        case .mfiTag:
            return PBMFiTag(withMacAddress: macAddress)
        case .mfiWhite:
            return PBMFiWhite(withMacAddress: macAddress)
        case .mfiGreen:
            return PBMFiGreen(withMacAddress: macAddress)
        case .mfiR4KTag:
            return PBMFiR4KTag(withMacAddress: macAddress)
        case .mfiCardV2:
            return PBMFiCardV2(withMacAddress: macAddress)
        case .mfiClipV2:
            return PBMFiClipV2(withMacAddress: macAddress)
        case .mfiTagV2:
            return PBMFiTagV2(withMacAddress: macAddress)
        case .unknown:
            return nil
        }
    }
    
    
    internal class func getDeviceInfo(fromData advertisementData: [String : Any]) -> (String, PBDeviceType)? {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else { return nil }
        
        let count = manufacturerData.count
        
        guard count > 6 else { return nil }
        
        // MARK: Legacy devices
        
        // extract subdata for components of the peripheral's expected MAC address
        let productIDRange = Range(uncheckedBounds: (0, 2))
        let productIDSubData = manufacturerData.subdata(in: productIDRange)
        // read the byte sequences of the subdata as big-endian UInt16 values
        var productID: UInt16 = 0
        productIDSubData.withUnsafeBytes( { (bytes: UnsafePointer<UInt16> ) in
            productID = UInt16(bytes.pointee.bigEndian)
        })
        
        let firstRange = Range(uncheckedBounds: (2, 2 + 4))
        let firstSubData = manufacturerData.subdata(in: firstRange)
        var firstInt: UInt16 = 0
        firstSubData.withUnsafeBytes( { (bytes: UnsafePointer<UInt16> ) in
            firstInt = UInt16(bytes.pointee.bigEndian)
        })
        
        let secondRange = Range(uncheckedBounds: (4, 4 + 2))
        let secondSubData = manufacturerData.subdata(in: secondRange)
        var secondInt: UInt16 = 0
        secondSubData.withUnsafeBytes( { (bytes: UnsafePointer<UInt16> ) in
            secondInt = UInt16(bytes.pointee.bigEndian)
        })
        
        if let product = Product(rawValue: productID) {
            let macAddress = String(format: "%04x%04x%04x", productID, firstInt, secondInt)
            
            return (macAddress, product.deviceType)
        } else {
            // MARK: - MFI Devices
            
            guard manufacturerData.count > 11 else { return nil }
            
            guard let mfiProduct = PBMFiIdentitifiers(rawValue: manufacturerData[2]) else { return nil }
            
            var macAddress: String
            
            switch mfiProduct {
            case .card,
                    .cardV2,
                    .clip,
                    .clipV2,
                    .tag,
                    .tagV2,
                    .white,
                    .green:
                macAddress = Data(manufacturerData.subdata(in: Range(uncheckedBounds: (5,11))).reversed()).hexEncodedString()
            case .rakTag:
                guard let advertisementName = advertisementData[CBAdvertisementDataLocalNameKey] as? String else { return nil }
                
                let las4MacAddress = String(advertisementName.suffix(4))
                
                macAddress = Data(manufacturerData.subdata(in: Range(uncheckedBounds: (8,12))).reversed()).hexEncodedString() + las4MacAddress
            }
            
            return (macAddress, mfiProduct.deviceType)
        }
    }
    
}


