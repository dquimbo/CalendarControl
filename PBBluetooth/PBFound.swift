//
//  PBFound15.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 26/01/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import Foundation
import Combine
import CoreLocation
import CoreBluetooth

/// Class that represents Pebblebee's Found with the latest Firmware.
public class PBFound: PBDevice {
    
    private let BATTERY_SERVICE = CBUUID(string: "180F")
    private let BATTERY_CHARACTERISTIC = CBUUID(string: "2A19")
    
    /// This represents the refresh rate we use to broadcast the updates. We wait this amount of seconds before *attempting* (Smart Mode check will take place too) to fire a Left Behind alert/
    override public var refreshRateInternal: TimeInterval {
        return 380
    }
    
    /// The current buzz state of the `PBFinder`. Changes for this value for any `PBFinder` are broadcast through the `PBFinderBuzzStateNotification`
    public internal(set) var buzzState: PBBuzzState = PBBuzzState.iddle {
        didSet{
            DispatchQueue.main.async {
                PBBroadcastManager.shared.stopLocalBeacon(self)
                
                NotificationCenter.default.post(name: PBFinderBuzzStateNotification, object: self)
            }
        }
    }
    
    /// The current advertisement state of the `PBFinder`. Changes for this value for any `PBFider` are broadcast through the `PBFinderAdvertisementStateNotification`.
    public internal(set) var advertisementState: PBFinderAdvertisementState = PBFinderAdvertisementState.unknown {
        didSet{
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: PBFinderAdvertisementStateNotification, object: self)
            }
        }
    }
    
    // MARK: - TOSHIBA PROTOCOL
    
    // Observable progress
    public var firmwareUpdateProgress: CurrentValueSubject<Int, Never> = CurrentValueSubject<Int, Never>(0)
    // Completion
    internal var toshibaOTACompletion: ((Result<Void, PBFirmwareUpdateError>) -> Void)?
    // Characteristics
    internal var toshibaSoftwareRevisionCharateristic: CBCharacteristic? {
        didSet {
            if gettingSoftwareRevision {
                readSoftwareRevision()
            }
        }
    }
    
    internal var toshibaHardwareRevisionCharateristic: CBCharacteristic? {
        didSet {
            if gettingHardwareRevision {
                readHardwareRevision()
            }
        }
    }
    internal var toshibaVersionCheckCharacteristic: CBCharacteristic? {
        didSet {
            if runningOTA {
                runningOTA = false
                writingVersionCheck = true
                writeVersionCheck()
            }
        }
    }
    internal var toshibaOpenFlashCharacteristic: CBCharacteristic?
    internal var toshibaCloseFlashCharacteristic: CBCharacteristic?
    internal var toshibaCheckflagCharacteristic: CBCharacteristic?
    internal var toshibaProcessEraseCharacteristic: CBCharacteristic?
    internal var toshibaMemoryWriteCharacteristic: CBCharacteristic?
    internal var toshibaChecksum1Characteristic: CBCharacteristic?
    internal var toshibaChecksum2Characteristic: CBCharacteristic?
    internal var toshibaFlagChangeCharacteristic: CBCharacteristic?
    // Flags
    internal var imageToOTA: Data = Data()
    internal var imageToOTASize: Int = 0
    internal var runningOTA: Bool = false
    internal var writingVersionCheck: Bool = false
    internal var openingMemory: Bool = false
    internal var writingFlagRead: Bool = false
    internal var writingProcessErase: Bool = false
    internal var currentProcessEraseStep: ToshibaProcessEraseStep = .header
    internal var writingMainProcess: Bool = false
    internal var verifyingChecksumA: Bool = false
    internal var verifyingChecksumB: Bool = false
    internal var writingEnd1: Bool = false
    internal var writingEnd2: Bool = false
    internal var changingFlag: Bool = false
    internal var closingMemory: Bool = false
    // Computed properties
    internal var BOOT_AREA_FLAG_ADDRESS: Int { return FLASH_B_HEADER_ADDRESS + 0x200 }
    internal var FLASH_A_HEADER_ADDRESS: Int { return 0x04000 }
    internal var FLASH_B_HEADER_ADDRESS: Int { return 0x05000 }
    // App0
    internal var FLASH_A_APP0_TOP_ADDRESS: Int { return 0x06000 }
    internal var FLASH_B_APP0_TOP_ADDRESS: Int { return 0x18000 }
    internal var FLASH_APP0_SIZE: Int { return 0x12000 }
    // App1
    internal var FLASH_A_APP1_TOP_ADDRESS: Int { return 0x20000 }
    internal var FLASH_B_APP1_TOP_ADDRESS: Int { return 0x21000 }
    internal var FLASH_APP1_SIZE: Int { return 0x00000 }
    // RAM
    var RAM_APP0_TOP_ADDRESS: Int { return 0x810B00 }
    var RAM_APP0_END_ADDRESS: Int { return 0x823B8B }
    var RAM_APP1_TOP_ADDRESS: Int { return 0x824000 }
    // Target indicators
    internal var MEMORY_SIDE_TO_WRITE: MemorySide = .sideA
    internal var TARGET_AREA_HEADER_START_ADDRESS: Int { MEMORY_SIDE_TO_WRITE == .sideA ? FLASH_A_HEADER_ADDRESS : FLASH_B_HEADER_ADDRESS }
    internal var TARGET_AREA_APP0_START_ADDRESS: Int { MEMORY_SIDE_TO_WRITE == .sideA ? FLASH_A_APP0_TOP_ADDRESS : FLASH_B_APP0_TOP_ADDRESS }
    internal var TARGET_AREA_APP1_START_ADDRESS: Int { MEMORY_SIDE_TO_WRITE == .sideA ? FLASH_A_APP1_TOP_ADDRESS : FLASH_B_APP1_TOP_ADDRESS }
    internal var filePointer: Int = 0
    internal var erasingAddress: Int = 0
    internal var mUpperAddress: Int = 0
    internal var writeProcessStep: ToshibaWriteMainProcessStep = .analysis
    internal var ramBuffer: [UInt8] = []
    internal var ramPointer: Int = 0
    internal var ramBufferPointer: Int = 0
    internal var ramBufferPointer2: Int = 0
    internal var checksumApp0: Int = 0
    internal var checksumApp1: Int = 0
    internal var mDataSizeApp0: Int = 0
    internal var mDataSizeApp1: Int = 0

    // MARK: - iBeacon
    
    public internal(set) var major: Int!
    public internal(set) var minor: Int!
    
    // MARK: - Buzzing
    
    private var needToBuzz = false
    private var buzzCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    private var needToStopBuzz = false
    private var stopBuzzCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    private var volumeChange = false
    private var newVolume: PBDeviceVolume?
    private var volumeChangeCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    
    // MARK: - Reboot
    
    private var rebooting = false
    private var rebootCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
        
    // MARK: - Tracking Period
    
    private var setTrackingMode = false
    private var getTrackingMode = false // Used to write on the characteristic to request the info, then readTrackingPeriod is set to true after writing
    private var readTrackingMode: Bool = false
    private var newTrackingMode: PBTrackingMode?
    private var getTrackingModeCompletion: ((Result<PBTrackingMode, PBBluetoothError>) -> Void)?
    private var setTrackingModeCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    
    // MARK: - IMEI
    
    private var getIMEI: Bool = false
    private var readIMEI: Bool = false
    private var getIMEICompletion: ((Result<String, PBBluetoothError>) -> Void)?
    
    // MARK: - LTE is Connected
    
    private var getLTEStatus: Bool = false
    private var readLTEStatus: Bool = false
    private var getLTEStatusCompletion: ((Result<PBCellularDeviceLTEStatus, PBBluetoothError>) -> Void)?
    
    // MARK: - ICCID
    
    private var getICCID: Bool = false
    private var readICCID: Bool = false
    private var getICCIDCompletion: ((Result<String, PBBluetoothError>) -> Void)?
    
    // MARK: - Charging Status
    
    private var getChargingStatus = false
    private var readChargingStatus = false
    private var chargingStatusCompletion: ((Result<PBChargingStatus, PBBluetoothError>) -> Void)?

    // MARK: - Device Info
    
    private var gettingSoftwareRevision = false
    private var gettingHardwareRevision = false
    private var softwareRevisionCompletion: ((Result<String, PBBluetoothError>) -> Void)?
    private var hardwareRevisionCompletion: ((Result<Bool, PBBluetoothError>) -> Void)?
    
    // MARK: - Debug Mode
    
    private var settingDebugMode = false
    private var debugModeToSet: Bool?
    private var gettingIsDebugModeOn = false
    private var setDebugModeCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    private var getIsDebugModeOnCompletion: ((Result<Bool, PBBluetoothError>) -> Void)?
    
    // Timer to controle timeout
    private var requestTimer: Timer?

    // MARK: - Characteristics
    private var batteryCharacteristic: CBCharacteristic?
    
    private var data1Characteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.needToBuzz {
                    self.writeForBuzz()
                } else if self.needToStopBuzz {
                    self.writeForStopBuzz()
                } else if self.volumeChange {
                    self.writeForVolumeChange()
                } else if self.setTrackingMode {
                    self.writeToSetTrackingMode()
                } else if self.rebooting {
                    self.writeForReboot()
                }
            }
        }
    }
    
    private var data2Characteristic: CBCharacteristic? {
        didSet{
            // Unused for now
        }
    }
    
    private var data3Characteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.getIMEI {
                    self.writeForIMEI()
                } else if self.getTrackingMode {
                    self.writeToGetTrackingPeriod()
                } else if self.getLTEStatus {
                    self.writeForLTEStatus()
                } else if self.getICCID {
                    self.writeForICCID()
                } else if self.getChargingStatus {
                    self.writeForChargingStatus()
                }
            }
        }
    }
    
    private var debugModeCharacteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.settingDebugMode {
                    self.writeToSetDebugMode()
                } else if self.gettingIsDebugModeOn {
                    self.readIsDebugModeOn()
                }
            }
        }
    }
        
    // MARK: - Init
    
    @objc internal required init(withAMacAddress mac: String, andMajor maj: Int, andMinor min: Int) {
        super.init(withMacAddress: mac)
        
        self.major = maj
        self.minor = min
        
        self.dataParser = PBFoundAdvertisementParser()
        
        self.deviceType = .found
    }
    
    // MARK: - Discover services
    
    override public func discoverServices() {
        self.peripheral?.discoverServices([finderServiceUUID, foundServiceUUID, BATTERY_SERVICE, TOSHIBA_DEVICE_INFO_SERVICE, TOSHIBA_STORAGE_SERVICE])
    }
}

// MARK: - PBBluetoothDevice

extension PBFound: PBBluetoothDevice {
    
    // Battery Reading
    
    public func getBatteryPercentage(withManufacturerData data: Data) -> Double? {
        guard data.count > 10 else { // Small broadcast, battery info not included
            return nil
        }
        
        let infoRange = data.subdata(in: Range(uncheckedBounds: (lower: 12, upper: 12 + MemoryLayout<UInt8>.size)))
        
        let percentage = (infoRange as NSData).bytes.bindMemory(to: UInt8.self, capacity: infoRange.count).pointee
        
        return Double(percentage)
    }
    
    // Buzz
    
    public func buzz(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.buzzCompletion = completion
        self.needToBuzz = true
        
        guard let state = self.connectionState else {
            buzzCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            buzzCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeForBuzz()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.buzzCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            buzzCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    // Stop Buzz
    
    public func stopBuzz(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.stopBuzzCompletion = completion
        self.needToStopBuzz = true
        
        guard let state = self.connectionState else {
            stopBuzzCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            stopBuzzCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeForStopBuzz()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.stopBuzzCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            stopBuzzCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    // Volume change
    
    public func setBuzzVolume(volume: PBDeviceVolume, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        volumeChangeCompletion = completion
        volumeChange = true
        newVolume = volume
        
        guard let state = self.connectionState else {
            volumeChangeCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            volumeChangeCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeForVolumeChange()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.volumeChangeCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            volumeChangeCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    public func setInDormantMode(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        completion(.failure(.featureNotAvailableInFirmware))
    }
    
}

// MARK: - PBCellularDevice

extension PBFound: PBCellularDevice {
    
    // Get IMEI
    
    public func getIMEI(completion: @escaping (Result<String, PBBluetoothError>) -> Void) {
        self.getIMEICompletion = { result in
            self.getIMEI = false
            self.readIMEI = false
            self.getIMEICompletion = nil
            
            DispatchQueue.main.async {
                switch result {
                case .success(let imei):
                    completion(.success(imei))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        self.getIMEI = true
        
        guard let state = self.connectionState else {
            self.getIMEICompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.getIMEICompletion?(.failure(.couldntConnectDevice))
        case .connected:
            self.writeForIMEI()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if let _ = error {
                    self?.getIMEICompletion?(.failure(.couldntConnectDevice))
               } else {
                    self?.discoverServices()
               }
           })
        default:
            return
        }
    }
    
    // Get tracking mode
    
    public func getTrackingMode(completion: @escaping (Result<PBTrackingMode, PBBluetoothError>) -> Void) {
        self.getTrackingModeCompletion = { result in
            self.getTrackingMode = false
            self.getTrackingModeCompletion = nil
            
            DispatchQueue.main.async {
                switch result {
                case .success(let mode):
                    completion(.success(mode))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        self.getTrackingMode = true
        
        guard let state = self.connectionState else {
            self.getTrackingModeCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.getTrackingModeCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            self.writeToGetTrackingPeriod()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.getTrackingModeCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            self.getTrackingModeCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    // Set tracking mode
    
    public func setTrackingMode(mode: PBTrackingMode, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        setTrackingModeCompletion = { result in
            self.setTrackingMode = false
            self.setTrackingModeCompletion = nil
            
            DispatchQueue.main.async {
                switch result {
                case .success():
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        setTrackingMode = true
        newTrackingMode = mode
        
        guard let state = self.connectionState else {
            self.setTrackingModeCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.setTrackingModeCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            self.writeToSetTrackingMode()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.setTrackingModeCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            self.setTrackingModeCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    // Get LTE Status
    
    public func getLTEStatus(completion: @escaping (Result<PBCellularDeviceLTEStatus, PBBluetoothError>) -> Void) {
        self.getLTEStatusCompletion = { result in
            self.getLTEStatus = false
            self.readLTEStatus = false
            self.getLTEStatusCompletion = nil
            
            DispatchQueue.main.async {
                switch result {
                case .success(let status):
                    completion(.success(status))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        self.getLTEStatus = true
        
        guard let state = self.connectionState else {
            self.getLTEStatusCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.getLTEStatusCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            self.writeForLTEStatus()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.getLTEStatusCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            self.getLTEStatusCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    // Get ICCID
    
    public func getICCID(completion: @escaping (Result<String, PBBluetoothError>) -> Void) {
        self.getICCIDCompletion = { result in
            self.getICCID = false
            self.readICCID = false
            self.getICCIDCompletion = nil
            
            DispatchQueue.main.async {
                switch result {
                case .success(let iccid):
                    completion(.success(iccid))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        self.getICCID = true
        
        guard let state = self.connectionState else {
            self.getICCIDCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.getICCIDCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            self.writeForICCID()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.getICCIDCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            self.getICCIDCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    /// Sets the debug mode on/off
    /// - Parameters:
    ///   - turnOn: Bool indicating if the debug mode should be ON.
    ///   - completion: Completion block, returns Void on success and a PBBluetoothError on failure.
    public func setDebugMode(turnOn: Bool, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        setDebugModeCompletion = { result in
            self.settingDebugMode = false
            self.setDebugModeCompletion = nil
            
            DispatchQueue.main.async {
                switch result {
                case .success():
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        settingDebugMode = true
        debugModeToSet = turnOn
        
        guard let state = self.connectionState else {
            self.setDebugModeCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.setDebugModeCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            self.writeToSetDebugMode()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.setDebugModeCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            self.setDebugModeCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    /// Retrieves if the debug mode is on.
    /// - Parameter completion: Completion block returns Bool indicating if the debug mode is running, when success. On failure returns a PBBluetoothError.
    public func getIsDebugModeOn(completion: @escaping (Result<Bool, PBBluetoothError>) -> Void) {
        self.getIsDebugModeOnCompletion = { result in
            self.gettingIsDebugModeOn = false
            self.getIsDebugModeOnCompletion = nil
            
            DispatchQueue.main.async {
                switch result {
                case .success(let isOn):
                    completion(.success(isOn))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        self.gettingIsDebugModeOn = true
        
        guard let state = self.connectionState else {
            self.getIsDebugModeOnCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.getIsDebugModeOnCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            self.readIsDebugModeOn()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.getIsDebugModeOnCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            self.getIsDebugModeOnCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
}

// MARK: - Private Methods

extension PBFound {
    
    // Read Hardware Revision
    private func readHardwareRevision() {
        guard gettingHardwareRevision, let characteristic = toshibaHardwareRevisionCharateristic, let peripheral = peripheral else {
            hardwareRevisionCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        peripheral.readValue(for: characteristic)
    }
    
    // Read Firmware Version
    private func readSoftwareRevision() {
        guard gettingSoftwareRevision, let characteristic = toshibaSoftwareRevisionCharateristic, let peripheral = peripheral else {
            softwareRevisionCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        peripheral.readValue(for: characteristic)
    }
    
    // Write for tracking mode
    private func writeToGetTrackingPeriod() {
        guard self.getTrackingMode, let characteristic = self.data3Characteristic else {
            self.getTrackingModeCompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let byte0 = UInt8(0x08)
        let byte1 = UInt8(0x05)
        let byte2 = UInt8(0x00)
        
        let pointer = [byte0, byte1 , byte2].withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = pointer else { return }
        
        let preriodData = Data(bytes: unwrappedPointer, count: 3 * MemoryLayout<UInt8>.size)
        
        self.peripheral?.writeValue(preriodData, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // Set tracking mode
    private func writeToSetTrackingMode() {
        guard self.setTrackingMode, let characteristic = self.data1Characteristic, let mode = newTrackingMode else {
            self.setTrackingModeCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        let bytePointer = [UInt8(0x08), UInt8(mode.rawValue)].withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            return
        }
        
        let data = Data(bytes: unwrappedPointer, count: 2 * MemoryLayout<UInt8>.size)
        self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // Write for IMEI
    private func writeForIMEI () {
        guard self.getIMEI, let characteristic = self.data3Characteristic else {
            self.getIMEICompletion?(.failure(.couldntConnectDevice))
            return
        }

        let bytes = [UInt8(0x04), UInt8(0x01), UInt8(0x00)]

        let pointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = pointer else { return }
        
        let imeiData = Data(bytes: unwrappedPointer, count: 3 * MemoryLayout<UInt8>.size)
        
        self.peripheral?.writeValue(imeiData, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // Write for Buzz
    private func writeForBuzz() {
        guard self.needToBuzz, let characteristic = self.data1Characteristic else {
            self.buzzCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        let bytePointer = [UInt8(0x01)].withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            return
        }
        
        let data = Data(bytes: unwrappedPointer, count: MemoryLayout<UInt8>.size)
        self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // Write for Stop Buzz
    private func writeForStopBuzz() {
        guard self.needToStopBuzz, let characteristic = self.data1Characteristic else {
            self.stopBuzzCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        let bytePointer = [UInt8(0x02)].withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            return
        }
        
        let data = Data(bytes: unwrappedPointer, count: MemoryLayout<UInt8>.size)
        self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // Write for Volume Change
    private func writeForVolumeChange() {
        guard self.volumeChange, let characteristic = self.data1Characteristic, let volume = newVolume else {
            self.volumeChangeCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        let byte: UInt8
        
        switch volume {
        case .mute:
            byte = 0x00
        case .low:
            byte = 0x01
        case .medium:
            byte = 0x02
        case .high:
            byte = 0x03
        }
        
        let bytePointer = [UInt8(0x03), UInt8(byte)].withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            return
        }
        
        let imeiData = Data(bytes: unwrappedPointer, count: 2 * MemoryLayout<UInt8>.size)
        self.peripheral?.writeValue(imeiData, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // Write for LTE Status
    private func writeForLTEStatus() {
        guard self.getLTEStatus, let characteristic = self.data3Characteristic else {
            self.getIMEICompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes = [UInt8(0x08), UInt8(0x04), UInt8(0x00)]

        let pointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = pointer else { return }
        
        let preriodData = Data(bytes: unwrappedPointer, count: 3 * MemoryLayout<UInt8>.size)
        
        self.peripheral?.writeValue(preriodData, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // Write for ICCID
    private func writeForICCID() {
        guard self.getICCID, let characteristic = self.data3Characteristic else {
            self.getICCIDCompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes = [UInt8(32), UInt8(128), UInt8(0)]
        
        let pointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = pointer else { return }
        
        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // Init variables for OTA
    private func setupAndInitOTAWrite() {
        writingProcessErase = false
        writingMainProcess = true
        
        filePointer = 0
        writeProcessStep = .analysis
        mUpperAddress = RAM_APP0_TOP_ADDRESS >> 16
        ramBufferPointer = 0
        ramBufferPointer2 = 0
        mDataSizeApp0 = 0
        mDataSizeApp1 = 0
        checksumApp0 = 0
        checksumApp1 = 0
        imageToOTASize = 0
        
        writeMainProcess()
    }
    
    // Write for reboot
    func writeForReboot() {
        guard self.rebooting, let characteristic = self.data1Characteristic else {
            self.rebootCompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes = [UInt8(0x07)]
        
        let pointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = pointer else { return }
        
        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        DispatchQueue.main.async {
            self.rebootCompletion?(.success(()))
        }
        
        self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // Write for chargingStatus
    func writeForChargingStatus() {
        guard self.getChargingStatus, let characteristic = self.data3Characteristic else {
            self.chargingStatusCompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes = [UInt8(0x08), UInt8(0x03), UInt8(0x00)]
        
        let pointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = pointer else { return }
        
        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // Set debug mode
    private func writeToSetDebugMode() {
        guard self.settingDebugMode, let characteristic = self.debugModeCharacteristic, let turnOn = debugModeToSet else {
            self.setDebugModeCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        let bytes = turnOn ? [UInt8(0x01)] : [UInt8(0x00)]
        
        let bytePointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            return
        }
        
        let data = Data(bytes: unwrappedPointer, count: MemoryLayout<UInt8>.size)
        self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    private func readIsDebugModeOn() {
        guard gettingIsDebugModeOn, let characteristic = debugModeCharacteristic, let peripheral = peripheral else {
            getIsDebugModeOnCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        peripheral.readValue(for: characteristic)
    }
}

// MARK: -  CBPeripheralDelegate

extension PBFound {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            switch service.uuid {
            case finderServiceUUID:
                peripheral.discoverCharacteristics([data1CharacteristicUUID, data2CharacteristicUUID,data3CharacteristicUUID], for: service)
                
            case foundServiceUUID:
                peripheral.discoverCharacteristics([debugModeCharacteristicUUID], for: service)
            
            case BATTERY_SERVICE:
                peripheral.discoverCharacteristics([BATTERY_CHARACTERISTIC], for: service)
                
            case TOSHIBA_DEVICE_INFO_SERVICE:
                peripheral.discoverCharacteristics([TOSHIBA_HARDWARE_REVISION_CHARACTERISTIC,
                                                    TOSHIBA_SOFTWARE_REVISION_CHARACTERISTIC], for: service)
            case TOSHIBA_STORAGE_SERVICE:
                peripheral.discoverCharacteristics([TOSHIBA_VERSION_CHECK_CHARACTERISTIC,
                                                    TOSHIBA_FLASH_OPEN_CHARACTERISTIC,
                                                    TOSHIBA_FLASH_CLOSE_CHARACTERISTIC,
                                                    TOSHIBA_PROCESS_CHECKFLAG_CHARACTERISTIC,
                                                    TOSHIBA_PROCESS_ERASE_CHARACTERISTIC,
                                                    TOSHIBA_MEMORY_WRITE_CHARACTERISTIC,
                                                    TOSHIBA_CHECKSUM1_CHARACTERISTIC,
                                                    TOSHIBA_CHECKSUM2_CHARACTERISTIC,
                                                    TOSHIBA_FLAGCHANGE_CHARACTERISTIC], for: service)
            default:
                return
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
            // Data
            case data1CharacteristicUUID:
                self.data1Characteristic = characteristic
            case data2CharacteristicUUID:
                self.data2Characteristic = characteristic
            case data3CharacteristicUUID:
                self.data3Characteristic = characteristic
                peripheral.setNotifyValue(true, for: self.data3Characteristic!)
                
            case debugModeCharacteristicUUID:
                self.debugModeCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: self.debugModeCharacteristic!)
                
            // Battery
            case BATTERY_CHARACTERISTIC:
                self.batteryCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: self.batteryCharacteristic!)
                
            // Device Info
            case TOSHIBA_HARDWARE_REVISION_CHARACTERISTIC:
                toshibaHardwareRevisionCharateristic = characteristic
            case TOSHIBA_SOFTWARE_REVISION_CHARACTERISTIC:
                toshibaSoftwareRevisionCharateristic = characteristic
                
            // OTA
            case TOSHIBA_VERSION_CHECK_CHARACTERISTIC:
                toshibaVersionCheckCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: self.toshibaVersionCheckCharacteristic!)
            case TOSHIBA_FLASH_OPEN_CHARACTERISTIC:
                toshibaOpenFlashCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: self.toshibaOpenFlashCharacteristic!)
            case TOSHIBA_FLASH_CLOSE_CHARACTERISTIC:
                toshibaCloseFlashCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: self.toshibaCloseFlashCharacteristic!)
            case TOSHIBA_PROCESS_CHECKFLAG_CHARACTERISTIC:
                toshibaCheckflagCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: self.toshibaCheckflagCharacteristic!)
            case TOSHIBA_PROCESS_ERASE_CHARACTERISTIC:
                toshibaProcessEraseCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: self.toshibaProcessEraseCharacteristic!)
            case TOSHIBA_MEMORY_WRITE_CHARACTERISTIC:
                toshibaMemoryWriteCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: self.toshibaMemoryWriteCharacteristic!)
            case TOSHIBA_CHECKSUM1_CHARACTERISTIC:
                toshibaChecksum1Characteristic = characteristic
                peripheral.setNotifyValue(true, for: self.toshibaChecksum1Characteristic!)
            case TOSHIBA_CHECKSUM2_CHARACTERISTIC:
                toshibaChecksum2Characteristic = characteristic
            case TOSHIBA_FLAGCHANGE_CHARACTERISTIC:
                toshibaFlagChangeCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: self.toshibaFlagChangeCharacteristic!)
            default:
                return
            }
        }
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let e = error {
            print(e)
        }
        
        DispatchQueue.main.async {
            switch characteristic.uuid {
            // Data
            case data3CharacteristicUUID:
                if let _ = error {
                    self.getIMEICompletion?(.failure(.errorWrittingInCharacteristic))
                    self.getICCIDCompletion?(.failure(.errorWrittingInCharacteristic))
                    self.getTrackingModeCompletion?(.failure(.errorWrittingInCharacteristic))
                    self.getLTEStatusCompletion?(.failure(.errorWrittingInCharacteristic))
                    self.chargingStatusCompletion?(.failure(.errorWrittingInCharacteristic))
                } else {
                    if self.getIMEI {
                        self.getIMEI = false
                        self.readIMEI = true
                    } else if self.getTrackingMode {
                        self.getTrackingMode = false
                        self.readTrackingMode = true
                    } else if self.getLTEStatus {
                        self.getLTEStatus = false
                        self.readLTEStatus = true
                    } else if self.getICCID {
                        self.getICCID = false
                        self.readICCID = true
                    } else if self.getChargingStatus {
                        self.getChargingStatus = false
                        self.readChargingStatus = true
                    }
                    
                    self.requestTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { _ in
                        self.getIMEICompletion?(.failure(.requestTimedOut))
                        self.getICCIDCompletion?(.failure(.requestTimedOut))
                        self.getTrackingModeCompletion?(.failure(.requestTimedOut))
                        self.getLTEStatusCompletion?(.failure(.requestTimedOut))
                        self.chargingStatusCompletion?(.failure(.requestTimedOut))
                    })
                }
            case data2CharacteristicUUID:
                break
            case data1CharacteristicUUID:
                if let _ = error {
                    self.buzzCompletion?(.failure(.errorWrittingInCharacteristic))
                    self.stopBuzzCompletion?(.failure(.errorWrittingInCharacteristic))
                    self.volumeChangeCompletion?(.failure(.errorWrittingInCharacteristic))
                    self.setTrackingModeCompletion?(.failure(.errorWrittingInCharacteristic))
                } else if self.needToBuzz {
                    self.needToBuzz = false
                    self.buzzCompletion?(.success(()))
                } else if self.needToStopBuzz {
                    self.needToStopBuzz = false
                    self.stopBuzzCompletion?(.success(()))
                } else if self.volumeChange {
                    self.volumeChange = false
                    self.volumeChangeCompletion?(.success(()))
                } else if self.setTrackingMode {
                    self.setTrackingMode = false
                    self.setTrackingModeCompletion?(.success(()))
                }
            case debugModeCharacteristicUUID:
                if let _ = error {
                    self.setDebugModeCompletion?(.failure(.errorWrittingInCharacteristic))
                } else if self.settingDebugMode {
                    self.settingDebugMode = false
                    self.setDebugModeCompletion?(.success(()))
                }
            // OTA
            case TOSHIBA_VERSION_CHECK_CHARACTERISTIC:
                guard error == nil else {
                    DispatchQueue.main.async {
                        self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
                    }
                    return
                }
                
                if self.writingVersionCheck { // Step 1
                    self.writingVersionCheck = false
                    self.openingMemory = true
                    self.openMemory()
                }
            case TOSHIBA_FLASH_OPEN_CHARACTERISTIC:
                DispatchQueue.main.async {
                    guard error == nil else {
                        self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
                        return
                    }
                    
                    self.openingMemory = false // Step 2
                    self.writingFlagRead = true
                    self.writeFlagRead()
                }
            case TOSHIBA_FLASH_CLOSE_CHARACTERISTIC:
                DispatchQueue.main.async {
                    guard error == nil else {
                        self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
                        return
                    }
                    
                    self.closingMemory = false // Step 11
                                    
                    self.toshibaOTACompletion?(.success(()))
                }
            case TOSHIBA_PROCESS_CHECKFLAG_CHARACTERISTIC:
                guard error == nil else {
                    DispatchQueue.main.async {
                        self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
                    }
                    return
                }
                
                if self.writingFlagRead { // Finished Step 3
                    self.writingFlagRead = false
                    self.writingProcessErase = true
                    self.currentProcessEraseStep = .header
                    self.erasingAddress = 0
                    self.writeProcessErase(step: self.currentProcessEraseStep)
                }
            case TOSHIBA_PROCESS_ERASE_CHARACTERISTIC:
                guard error == nil else {
                    DispatchQueue.main.async {
                        self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
                    }
                    return
                }
                
                if self.writingProcessErase {
                    switch self.currentProcessEraseStep {
                    case .header: // Finished Step 4.1
                        self.currentProcessEraseStep = .app0
                        self.erasingAddress = self.TARGET_AREA_APP0_START_ADDRESS
                        
                        if self.erasingAddress < self.TARGET_AREA_APP0_START_ADDRESS + self.FLASH_APP0_SIZE {
                            self.writeProcessErase(step: self.currentProcessEraseStep)
                        } else {
                            self.currentProcessEraseStep = .app1
                            self.erasingAddress = self.TARGET_AREA_APP1_START_ADDRESS
                            
                            if self.erasingAddress < self.TARGET_AREA_APP1_START_ADDRESS + self.FLASH_APP1_SIZE {
                                self.writeProcessErase(step: self.currentProcessEraseStep)
                            } else {
                                self.setupAndInitOTAWrite()
                            }
                        }
                    case .app0: // Finishing Step 4.2
                        self.erasingAddress = self.erasingAddress + 0x1000
                        
                        if self.erasingAddress < self.TARGET_AREA_APP0_START_ADDRESS + self.FLASH_APP0_SIZE {
                            self.writeProcessErase(step: self.currentProcessEraseStep)
                        } else {
                            self.currentProcessEraseStep = .app1
                            self.erasingAddress = self.TARGET_AREA_APP1_START_ADDRESS
                            
                            if self.erasingAddress < self.TARGET_AREA_APP1_START_ADDRESS + self.FLASH_APP1_SIZE {
                                self.writeProcessErase(step: self.currentProcessEraseStep)
                            } else {
                                self.setupAndInitOTAWrite()
                            }
                        }
                    case .app1: // Finishing Step 4.3
                        self.erasingAddress = self.erasingAddress + 0x1000
                        
                        if self.erasingAddress < self.TARGET_AREA_APP1_START_ADDRESS + self.FLASH_APP1_SIZE {
                            self.writeProcessErase(step: self.currentProcessEraseStep)
                        } else {
                            self.setupAndInitOTAWrite()
                        }
                    }
                }
            case TOSHIBA_MEMORY_WRITE_CHARACTERISTIC:
                guard error == nil else {
                    DispatchQueue.main.async {
                        self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
                    }
                    return
                }
                
                if self.writingEnd1 { // Step 8
                    self.writingEnd1 = false
                    self.writingEnd2 = true
                    self.writeEnd2()
                } else if self.writingEnd2 { // Step 9
                    self.writingEnd2 = false
                    self.changingFlag = true
                    self.writeFlagChange() // Step 10
                } else if self.writingMainProcess {
                    if self.ramBufferPointer == self.ramBufferPointer2 {
                        self.setWriteProcessStep(step: .analysis)
                    }
                    
                    self.writeMainProcess() // Step 5
                }
            case TOSHIBA_CHECKSUM1_CHARACTERISTIC:
                guard let checksum2Characteristic = self.toshibaChecksum2Characteristic else {
                    self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
                    
                    return
                }
                
                if self.writingMainProcess {
                    self.writingMainProcess = false
                    self.verifyingChecksumA = true
                }
                
                peripheral.readValue(for: checksum2Characteristic) // Step 6 & 7
            case TOSHIBA_FLAGCHANGE_CHARACTERISTIC:
                guard error == nil else {
                    DispatchQueue.main.async {
                        self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
                    }
                    return
                }
                
                self.changingFlag = false
                self.closingMemory = true
                self.closeMemory()
            default:
                return
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        DispatchQueue.main.async {
            switch characteristic.uuid {
            case data3CharacteristicUUID:
                guard let data = characteristic.value else {
                    return
                }
                
                self.requestTimer?.invalidate()
                self.requestTimer = nil
                
                if data.count > 3, data.starts(with: [8,9,0]) { // Button action
                    let actionByte = data[3]
                    
                    switch actionByte {
                    case 0x00:
                        self.buttonState = .singlePress
                    case 0x01:
                        self.buttonState = .doublePress
                    case 0x02:
                        self.buttonState = .longPress
                    default:
                        return
                    }
                } else if self.readIMEI == true {
                    self.readIMEI = false
                    
                    let subdata = data.subdata(in:Range(uncheckedBounds: (lower: 3, upper: 3 + MemoryLayout<UInt8>.size * 15)))
                    
                    if let imei = String(data: subdata, encoding: String.Encoding.utf8) {
                        self.getIMEICompletion?(.success(imei))
                    } else {
                        self.getIMEICompletion?(.failure(.errorReadingValueFromCharacteristic))
                    }
                } else if self.readTrackingMode {
                    self.readTrackingMode = false
                    
                    if data.count > 3, let trackingMode = PBTrackingMode(rawValue: data[3]) {
                        self.getTrackingModeCompletion?(.success(trackingMode))
                    } else {
                        self.getTrackingModeCompletion?(.failure(.errorReadingValueFromCharacteristic))
                    }
                } else if self.readLTEStatus {
                    self.readLTEStatus = false
                    
                    if data.count > 3 {
                        self.getLTEStatusCompletion?(.success(data[3] == 0 ? .disconnected : .connected))
                    } else {
                        self.getLTEStatusCompletion?(.failure(.errorReadingValueFromCharacteristic))
                    }
                } else if self.readICCID {
                    self.readICCID = false
                    
                    let subdata = data.subdata(in:Range(uncheckedBounds: (lower: 3, upper: 3 + MemoryLayout<UInt8>.size * 10)))
                    
                    self.getICCIDCompletion?(.success(subdata.hexEncodedString()))
                } else if self.readChargingStatus {
                    self.readChargingStatus = false
                    
                    if data.count > 3 {
                        self.chargingStatusCompletion?(.success(data[3] == 0 ? .notCharging : .charging))
                    } else {
                        self.chargingStatusCompletion?(.failure(.errorReadingValueFromCharacteristic))
                    }
                }
                
            // Device Info
            case debugModeCharacteristicUUID:
                guard let data = characteristic.value else {
                    return
                }
                
                self.gettingIsDebugModeOn = false
                
                self.getIsDebugModeOnCompletion?(.success(data.first == 0x01))
                
            // Battery
            case self.BATTERY_CHARACTERISTIC:
                guard let data = characteristic.value, let percentage = data.first else {
                    return
                }
                
                self.batteryPercentage = Double(percentage)
                
                peripheral.setNotifyValue(false, for: self.batteryCharacteristic!)
                
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 60) {
                    peripheral.setNotifyValue(true, for: self.batteryCharacteristic!)
                }
                
            // Device Info
            case TOSHIBA_SOFTWARE_REVISION_CHARACTERISTIC:
                guard let data = characteristic.value, let versionString = String(data: data, encoding: String.Encoding.utf8) else {
                    return
                }
                
                self.gettingSoftwareRevision = false
                
                self.softwareRevisionCompletion?(.success(versionString))
            case TOSHIBA_HARDWARE_REVISION_CHARACTERISTIC:
                guard let data = characteristic.value, let versionString = String(data: data, encoding: String.Encoding.utf8) else {
                    return
                }
                
                self.gettingHardwareRevision = false
                
                self.hardwareRevisionCompletion?(.success(!versionString.contains("BL.")))
            // OTA
            case TOSHIBA_CHECKSUM2_CHARACTERISTIC:
                guard let data = characteristic.value, data.count ==  4 else {
                    self.toshibaOTACompletion?(.failure(.failedChecksumVerification))
                    
                    return
                }
                
                let checksumReceived: Int = ((Int(data[0]) << 24) & 0xFF000000) |
                                            ((Int(data[1]) << 16) & 0x00FF0000) |
                                            ((Int(data[2]) << 8) & 0x0000FF00) |
                                            (Int(data[3]) & 0x000000FF)
                
                if self.verifyingChecksumA {
                    self.verifyingChecksumA = false
                    
                    if checksumReceived == self.checksumApp0 {
                        self.verifyingChecksumB = true
                        self.writeForChecksum1B()
                    } else {
                        self.toshibaOTACompletion?(.failure(.failedChecksumVerification))
                    }
                } else if self.verifyingChecksumB {
                    self.verifyingChecksumB = false
                    
                    if checksumReceived == self.checksumApp1 {
                        self.writingEnd1 = true
                        self.writeEnd1()
                    } else {
                        self.toshibaOTACompletion?(.failure(.failedChecksumVerification))
                    }
                }
            default:
                return
            }
        }
    }
        
}

// MARK: Class Functions

extension PBFound {
    
    /// Bits used for iBeacon
    class func getMajorMinor(fromData d: Data) -> (Int, Int)? {
            let majorRange = Range(uncheckedBounds: (2, 2 + 4))
        let majorSubdata = d.subdata(in: majorRange)
        let minorRange = Range(uncheckedBounds: (4, 4 + 2))
        let minorSubdata = d.subdata(in: minorRange)
        
        
        var major: UInt16 = 0
        majorSubdata.withUnsafeBytes( { (bytes: UnsafePointer<UInt16> ) in
            major = UInt16(bytes.pointee.bigEndian)
        })
        var minor: UInt16 = 0
        minorSubdata.withUnsafeBytes( { (bytes: UnsafePointer<UInt16> ) in
            minor = UInt16(bytes.pointee.bigEndian)
        })
        
        return (Int(major), Int(minor))
    }
    
}

// MARK: - PBToshibaChipProtocol

extension PBFound: PBBluetoothUpdatableDevice, PBToshibaChipProtocol {
    
    func setFilePointer(pointer: Int) {
        self.filePointer = pointer
    }
    
    func setUpperAddress(mUpperAddress: Int) {
        self.mUpperAddress = mUpperAddress
    }
    
    func setRamBuffer(buffer: [UInt8]) {
        self.ramBuffer = buffer
    }
    
    func setRamBufferAtIndex(byte: UInt8, index: Int) {
        self.ramBuffer[index] = byte
    }
    
    func setRamPointer(pointer: Int) {
        self.ramPointer = pointer
    }
    
    func setRamBufferPointer(pointer: Int) {
        self.ramBufferPointer = pointer
    }
    
    func setRamBufferPointer2(pointer: Int) {
        self.ramBufferPointer2 = pointer
    }
    
    func setChecksumApp0(checksum: Int) {
        self.checksumApp0 = checksum
    }
    
    func setChecksumApp1(checksum: Int) {
        self.checksumApp1 = checksum
    }
    
    func setDataSizeApp0(dataSize: Int) {
        self.mDataSizeApp0 = dataSize
    }
    
    func setDataSizeApp1(dataSize: Int) {
        self.mDataSizeApp1 = dataSize
    }
    
    func setWriteProcessStep(step: ToshibaWriteMainProcessStep) {
        self.writeProcessStep = step
    }
    
    public func runOTA(image: Data, completion: @escaping (Result<Void, PBFirmwareUpdateError>) -> Void) {
        self.imageToOTA = image
        
        self.runToshibaOTA(image: image, completion: completion)
    }
    
    // Software Revision
    
    public func getFirmwareVersion(completion: @escaping (Result<String, PBBluetoothError>) -> Void) {
        self.softwareRevisionCompletion = { result in
            self.gettingSoftwareRevision = false
            self.softwareRevisionCompletion = nil
            
            DispatchQueue.main.async {
                switch result {
                case .success(let version):
                    completion(.success(version))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        self.gettingSoftwareRevision = true
        
        guard let state = self.connectionState else {
            softwareRevisionCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            softwareRevisionCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            readSoftwareRevision()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.softwareRevisionCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            softwareRevisionCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    // Hardware Revision
    
    public func verifyHardwareRevision(completion: @escaping (Result<Bool, PBBluetoothError>) -> Void) {
        self.hardwareRevisionCompletion = { result in
            self.gettingHardwareRevision = false
            self.hardwareRevisionCompletion = nil
            
            DispatchQueue.main.async {
                switch result {
                case .success(let verified):
                    completion(.success(verified))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        self.gettingHardwareRevision = true
        
        guard let state = self.connectionState else {
            hardwareRevisionCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            hardwareRevisionCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            readHardwareRevision()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.hardwareRevisionCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            hardwareRevisionCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    // OTA update
    
    func runToshibaOTA(image: Data, completion: @escaping (Result<Void, PBFirmwareUpdateError>) -> Void) {
        toshibaOTACompletion = { result in
            DispatchQueue.main.async {
                self.firmwareUpdateProgress.send(0)
                
                switch result {
                case .success():
                    completion(.success(()))
                case .failure(let error):
                    self.runningOTA = false
                    self.writingVersionCheck = false
                    self.openingMemory = false
                    self.writingFlagRead = false
                    self.writingProcessErase = false
                    self.currentProcessEraseStep = .header
                    self.writingMainProcess = false
                    self.writingEnd1 = false
                    self.writingEnd2 = false
                    self.changingFlag = false
                    self.closingMemory = false
                    
                    completion(.failure(error))
                }
            }
        }
        
        runningOTA = true
        writingVersionCheck = false
        openingMemory = false
        writingFlagRead = false
        writingProcessErase = false
        currentProcessEraseStep = .header
        writingMainProcess = false
        writingEnd1 = false
        writingEnd2 = false
        changingFlag = false
        closingMemory = false
        
        guard let state = self.connectionState else {
            toshibaOTACompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            toshibaOTACompletion?(.failure(.couldntConnectDevice))
        case .connected:
            runningOTA = false
            writingVersionCheck = true
            writeVersionCheck()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.toshibaOTACompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            toshibaOTACompletion?(.failure(.couldntDetermineDeviceState))
        }
    }

}

// MARK: - PBRebootableDevice

extension PBFound: PBRebootableDevice {
    
    public func reboot(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.rebootCompletion = { result in
            self.rebooting = false
            self.rebootCompletion = nil
            
            DispatchQueue.main.async {
                switch result {
                case .success():
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        self.rebooting = true
        
        guard let state = self.connectionState else {
            rebootCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            rebootCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeForReboot()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.rebootCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            rebootCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
}

// MARK: - PBCharhingStatusReporter

extension PBFound: PBChargingStatusReporter {
    
    public func getChargingStatus(completion: @escaping (Result<PBChargingStatus, PBBluetoothError>) -> Void) {
        self.chargingStatusCompletion = { result in
            self.getChargingStatus = false
            self.chargingStatusCompletion = nil
            
            DispatchQueue.main.async {
                switch result {
                case .success(let status):
                    completion(.success(status))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        self.getChargingStatus = true
        
        guard let state = self.connectionState else {
            chargingStatusCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            chargingStatusCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeForChargingStatus()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.chargingStatusCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            chargingStatusCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
}

// MARK: - PBDeviceAutoConnectable
 
extension PBFound: PBDeviceAutoConnectable {
    
    public func getNewRSSI() {
        peripheral?.readRSSI()
    }
    
    public func attemptToReconnect() {
        PBBluetoothManager.shared.connectDevice(device: self) {[weak self] (error) in
            guard error == nil else { return }
            
            self?.discoverServices()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NotificationCenter.default.post(name: PBDeviceAutoConnectableNotification, object: self)
            }
        }
    }
    
}




