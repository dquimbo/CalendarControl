//
//  PBFound15.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 26/01/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import UIKit
import Combine
import CoreBluetooth

/// The PBFound version compatible with advertised Model Number 14
public class PBFoundRC: PBFinder1 {
    
    private let BATTERY_SERVICE = CBUUID(string: "180F")
    private let BATTERY_CHARACTERISTIC = CBUUID(string: "2A19")
    
    /// This represents the refresh rate we use to broadcast the updates. We wait this amount of seconds before *attempting* (Smart Mode check will take place too) to fire a Left Behind alert/
    override public var refreshRateInternal: TimeInterval {
        return 380
    }
    
    // MARK: - TOSHIBA PROTOCOL
    
    // Observable progress
    public var firmwareUpdateProgress: CurrentValueSubject<Int, Never> = CurrentValueSubject<Int, Never>(0)
    // Completion
    internal var toshibaOTACompletion: ((Result<Void, PBFirmwareUpdateError>) -> Void)?
    // Characteristics
    private var batteryCharacteristic: CBCharacteristic?
    
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
    // Properties
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
    
    // MARK: - IMEI
    
    private var getIMEI: Bool = false
    private var readIMEI: Bool = false
    private var getIMEICompletion: ((_ imie: String?, _ error: PBSetGenericError?) -> Void)?
    
    // MARK: - ICCID
    
    private var getICCID: Bool = false
    private var readICCID: Bool = false
    private var getICCIDCompletion: ((Result<String, PBBluetoothError>) -> Void)?

    // MARK: - Device Info
    
    private var gettingSoftwareRevision = false
    private var gettingHardwareRevision = false
    private var softwareRevisionCompletion: ((Result<String, PBBluetoothError>) -> Void)?
    private var hardwareRevisionCompletion: ((Result<Bool, PBBluetoothError>) -> Void)?

    // MARK: - Data Characteristics
    
    @objc internal var data3Characteristic: CBCharacteristic? {
        didSet{
            if getIMEI {
                writeForIMEI()
            } else if getICCID {
                writeForICCID()
            }
        }
    }
    
    // MARK: - Init
    
    @objc internal required init(withAMacAddress mac: String, andMajor maj: Int, andMinor min: Int) {
        super.init(withAMacAddress: mac,andMajor: maj, andMinor: min)
        self.dataParser = PBFoundRCAdvertisementParser()
        self.deviceType = .found
    }
    
    // MARK: - Discover services
    
    override public func discoverServices() {
        self.peripheral?.discoverServices([finderServiceUUID, BATTERY_SERVICE, TOSHIBA_DEVICE_INFO_SERVICE, TOSHIBA_STORAGE_SERVICE])
    }
    
    // MARK: - Public methods
    
    // Battery Reading
    /// This function extracts, if present, the battery volts or percentage
    ///
    /// - Parameter data: The data from where the battery should be extracted. Each PBDevice should implement this methods if it's able to return battery info.
    /// - Returns: `PBBatteryReading` object with volts and/or percentage, if the battery info is present. When not, returns `nil`.
    override public func getBatteryPercentage(withManufacturerData data: Data) -> Double? {
        guard data.count > 10 else { // Small broadcast, battery info not included
            return nil
        }
        
        let infoRange = data.subdata(in: Range(uncheckedBounds: (lower: 12, upper: 12 + MemoryLayout<UInt8>.size)))
        
        let percentage = (infoRange as NSData).bytes.bindMemory(to: UInt8.self, capacity: infoRange.count).pointee
        
        return Double(percentage)
    }
}

// MARK: - Private Methods

extension PBFoundRC {
    
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
    
    // Write to read IMEI
    private func writeForIMEI () {
        guard self.getIMEI, let characteristic = self.data3Characteristic else {
            self.getIMEICompletion?(nil, PBSetGenericError.notConnected)
            return
        }

        let bytes = [UInt8(0x04), UInt8(0x01), UInt8(0x00)]
        
        let pointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = pointer else { return }
        
        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // Read IMEI
    private func getIMEI(withManager m: PBBluetoothManager?, completion: @escaping (_ imei: String?, _ error: PBSetGenericError?) -> Void) {
        print(#function)
        self.getIMEICompletion = completion
        self.getIMEI = true
        guard let state = self.connectionState else {
            self.getIMEICompletion?(nil, PBSetGenericError.notConnected)
            return
        }
        switch state {
        case .connecting, .disconnecting:
            self.getIMEICompletion?(nil, PBSetGenericError.notConnected)
        case .connected:
            self.writeForIMEI()
        case .disconnected:
           guard let manager = m else {
               self.getIMEICompletion?(nil, PBSetGenericError.notConnected)
               return
           }
           
           manager.connectDevice(device: self, completion: { (error) in
               if let e = error {
                   self.getIMEICompletion?(nil, PBSetGenericError.connectionFail(error: e))
               }else{
                   self.discoverServices()
               }
           })
        default:
            return
        }
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
    
}

// MARK: - CBPeripheralDelegate Methods

extension PBFoundRC {
    override public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            switch service.uuid {
            case finderServiceUUID:
                peripheral.discoverCharacteristics([data1CharacteristicUUID, data2CharacteristicUUID,data3CharacteristicUUID], for: service)
                
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
    
    override public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
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
                
            // Battery
            case BATTERY_CHARACTERISTIC:
                self.batteryCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            
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
    
    public override func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let e = error {
            print(e)
        }
        switch characteristic.uuid {
        // Data
        case data3CharacteristicUUID:
            if let e = error {
                DispatchQueue.main.async {
                    self.getIMEICompletion?(nil, PBSetGenericError.bluetoothError(error: e))
                }
            } else {
                DispatchQueue.main.async {
                    if self.getIMEI {
                        self.getIMEI = false
                        self.readIMEI = true
                        peripheral.readValue(for: characteristic)
                    } else if self.getICCID {
                        self.getICCID = false
                        self.readICCID = true
                        peripheral.readValue(for: characteristic)
                    }
                }
            }
        case data2CharacteristicUUID:
            break
        case data1CharacteristicUUID:
            if let e = error {
                DispatchQueue.main.async {
                    self.findCompletion?(PBFinderFindError.bluetoothError(error: e))
                    self.setDormantCompletion?(PBSetDormantError.bluetoothError(error: e))
                    self.setJingleCompletion?(PBSetGenericError.bluetoothError(error: e))
                    self.setVolumeCompletion?(PBSetGenericError.bluetoothError(error: e))
                    self.setRebootCompletion?(PBSetGenericError.bluetoothError(error: e))
                    self.setCancelBuzzCompletion?(PBSetGenericError.bluetoothError(error: e))
                    self.resetDeviceCompletion?(PBSetGenericError.bluetoothError(error: e))
                }
            }else{
                DispatchQueue.main.async {
                    self.findCompletion?(nil)
                    self.needToBuzz = false
                    self.buzzType = nil
                    self.needToWakeUp = false
                    self.setDormantCompletion?(nil)
                    self.setOTACompletion?(nil)
                    self.setCancelBuzzCompletion?(nil)
                    self.setRebootCompletion?(nil)
                    self.setJingleCompletion?(nil)
                    self.setVolumeCompletion?(nil)
                    self.setDormant = false
                    self.setOTA = false
                    self.setCancelBuzz = false
                    self.setReboot = false
                    self.setJingle = false
                    self.setVolume = false
                    self.setVolumeValue = 3
                    self.setJingleValue = 2
                    self.resetDeviceCompletion?(nil)
                    self.resetDevice = false
                    
                }

            }
            
        // OTA
        case TOSHIBA_VERSION_CHECK_CHARACTERISTIC:
            DispatchQueue.main.async {
                guard error == nil else {
                    self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
                    return
                }
                
                if self.writingVersionCheck { // Step 1
                    self.writingVersionCheck = false
                    self.openingMemory = true
                    self.openMemory()
                }
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
            DispatchQueue.main.async {
                guard error == nil else {
                    self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
                    return
                }
                
                if self.writingFlagRead { // Finished Step 3
                    self.writingFlagRead = false
                    self.writingProcessErase = true
                    self.currentProcessEraseStep = .header
                    self.erasingAddress = 0
                    self.writeProcessErase(step: self.currentProcessEraseStep)
                }
            }
        case TOSHIBA_PROCESS_ERASE_CHARACTERISTIC:
            DispatchQueue.main.async {
                guard error == nil else {
                    self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
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
            }
        case TOSHIBA_MEMORY_WRITE_CHARACTERISTIC:
            DispatchQueue.main.async {
                guard error == nil else {
                    self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
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
            }
        case TOSHIBA_CHECKSUM1_CHARACTERISTIC:
            DispatchQueue.main.async {
                guard error == nil else {
                    self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
                    return
                }
                
                guard let checksum2Characteristic = self.toshibaChecksum2Characteristic else {
                    self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
                    
                    return
                }
                
                if self.writingMainProcess {
                    self.writingMainProcess = false
                    self.verifyingChecksumA = true
                }
                
                peripheral.readValue(for: checksum2Characteristic) // Step 6 & 7
            }
        case TOSHIBA_FLAGCHANGE_CHARACTERISTIC:
            DispatchQueue.main.async {
                guard error == nil else {
                    self.toshibaOTACompletion?(.failure(.errorWrittingInCharacteristic))
                    return
                }
                
                self.changingFlag = false
                self.closingMemory = true
                self.closeMemory()
            }
        default:
            return
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        DispatchQueue.main.async {
            switch characteristic.uuid {
            case data3CharacteristicUUID:
                guard let data = characteristic.value else {
                    return
                }
                
                if self.readIMEI == true {
                    self.readIMEI = false

                    let cmd1: UInt8 = data[0]
                    
                    guard cmd1 != 0 else {
                        //Must read again
                        self.getIMEI = true
                        self.writeForIMEI()
                        return
                    }
                    
                    let subdata = data.subdata(in:Range(uncheckedBounds: (lower: 3, upper: 3 + MemoryLayout<UInt8>.size * 15)))
                    let imei = String(data: subdata, encoding: String.Encoding.utf8) ?? ""

                    self.getIMEICompletion?(imei, nil)
                } else if self.readICCID {
                    self.readICCID = false
                    
                    let cmd1: UInt8 = data[0]
                    
                    guard cmd1 != 0 else {
                        //Must read again
                        self.getICCID = true
                        self.writeForICCID()
                        return
                    }
                    
                    let subdata = data.subdata(in:Range(uncheckedBounds: (lower: 3, upper: 3 + MemoryLayout<UInt8>.size * 10)))
                    
                    self.getICCIDCompletion?(.success(subdata.hexEncodedString()))
                }
                
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

// MARK: - PBCellularDevice

extension PBFoundRC: PBCellularDevice {
    
    // Debug Mode
    
    public func setDebugMode(turnOn: Bool, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        completion(.failure(.featureNotAvailableInFirmware))
    }
    
    public func getIsDebugModeOn(completion: @escaping (Result<Bool, PBBluetoothError>) -> Void) {
        completion(.failure(.featureNotAvailableInFirmware))
    }
    
    
    // Get IMEI
    
    public func getIMEI(completion: @escaping (Result<String, PBBluetoothError>) -> Void) {
        self.getIMEI(withManager: PBBluetoothManager.shared) { (imei, error) in
            guard let imeiString = imei, error == nil else {
                completion(.failure(.couldntConnectDevice))
                
                return
            }
            
            completion(.success(imeiString))
        }
    }
    
    // Get tracking mode
    
    public func getTrackingMode(completion: @escaping (Result<PBTrackingMode, PBBluetoothError>) -> Void) {
        completion(.failure(.featureNotAvailableInFirmware))
    }
    
    // Set tracking mode
    
    public func setTrackingMode(mode: PBTrackingMode, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        completion(.failure(.featureNotAvailableInFirmware))
    }
    
    // Get LTE Status
    
    public func getLTEStatus(completion: @escaping (Result<PBCellularDeviceLTEStatus, PBBluetoothError>) -> Void) {
        completion(.failure(.featureNotAvailableInFirmware))
    }
    
    // Get ICCID
    
    public func getICCID(completion: @escaping (Result<String, PBBluetoothError>) -> Void) {
        self.getICCIDCompletion = completion
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
}

// MARK: - PBToshibaChipProtocol

extension PBFoundRC: PBBluetoothUpdatableDevice, PBToshibaChipProtocol {
    
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
        self.softwareRevisionCompletion = completion
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
        self.hardwareRevisionCompletion = completion
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
