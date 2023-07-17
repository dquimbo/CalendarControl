//
//  PBToshibaChip.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 01/02/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import Combine
import CoreBluetooth

// Constants

let TOSHIBA_FLAG_AREA_SIZE = 0xE00

// Services

let TOSHIBA_STORAGE_SERVICE = CBUUID(string: "53616D70-6C65-4170-7044-656D6F010000")

let TOSHIBA_DEVICE_INFO_SERVICE = CBUUID(string: "0000180a-0000-1000-8000-00805f9b34fb")

// Characteristics UUID

let TOSHIBA_SOFTWARE_REVISION_CHARACTERISTIC = CBUUID(string: "00002a28-0000-1000-8000-00805f9b34fb")

let TOSHIBA_HARDWARE_REVISION_CHARACTERISTIC = CBUUID(string: "00002a27-0000-1000-8000-00805f9b34fb")

let TOSHIBA_FLASH_OPEN_CHARACTERISTIC = CBUUID(string: "53616d70-6c65-4170-7044-656d6f010001")

let TOSHIBA_VERSION_CHECK_CHARACTERISTIC = CBUUID(string: "53616d70-6c65-4170-7044-656d6f01000c")

let TOSHIBA_PROCESS_CHECKFLAG_CHARACTERISTIC = CBUUID(string: "53616d70-6c65-4170-7044-656d6f010009")

let TOSHIBA_PROCESS_ERASE_CHARACTERISTIC = CBUUID(string: "53616d70-6c65-4170-7044-656d6f010007")

let TOSHIBA_MEMORY_WRITE_CHARACTERISTIC = CBUUID(string: "53616d70-6c65-4170-7044-656d6f010008")

let TOSHIBA_CHECKSUM1_CHARACTERISTIC = CBUUID(string: "53616d70-6c65-4170-7044-656d6f010005")

let TOSHIBA_CHECKSUM2_CHARACTERISTIC = CBUUID(string: "53616d70-6c65-4170-7044-656d6f010006")

let TOSHIBA_FLAGCHANGE_CHARACTERISTIC = CBUUID(string: "53616d70-6c65-4170-7044-656d6f01000b")

let TOSHIBA_FLASH_CLOSE_CHARACTERISTIC = CBUUID(string: "53616d70-6c65-4170-7044-656d6f010002")

// MARK: - Enums

enum ToshibaProcessEraseStep {
    case header
    case app0
    case app1
}

enum MemorySide {
    case sideA
    case sideB
}

enum ToshibaWriteMainProcessStep {
    case analysis
    case write
    case checksum1A
}

enum WriteAnalytisState {
    case start
    case running
    case end
}

// MARK: - PBBluetoothUpdatableDevice

protocol PBToshibaChipProtocol: PBBluetoothUpdatableDevice {
    
    // Addresses
    // Header
    var FLASH_A_HEADER_ADDRESS: Int { get }
    var FLASH_B_HEADER_ADDRESS: Int { get }
    // App0
    var FLASH_A_APP0_TOP_ADDRESS: Int { get }
    var FLASH_B_APP0_TOP_ADDRESS: Int { get }
    var FLASH_APP0_SIZE: Int { get }
    // App1
    var FLASH_A_APP1_TOP_ADDRESS: Int { get }
    var FLASH_B_APP1_TOP_ADDRESS: Int { get }
    var FLASH_APP1_SIZE: Int { get }
    // RAM
    var RAM_APP0_TOP_ADDRESS: Int { get }
    var RAM_APP0_END_ADDRESS: Int { get }
    var RAM_APP1_TOP_ADDRESS: Int { get }
    // Memory
    var BOOT_AREA_FLAG_ADDRESS: Int { get }
    // TARGET SIDE INDICATORS
    var MEMORY_SIDE_TO_WRITE: MemorySide { get set }
    var TARGET_AREA_HEADER_START_ADDRESS: Int { get }
    var TARGET_AREA_APP0_START_ADDRESS: Int { get }
    var TARGET_AREA_APP1_START_ADDRESS: Int { get }
    // Main Write Process Variables
    var filePointer: Int { get set }
    var writeProcessStep: ToshibaWriteMainProcessStep { get set }
    var erasingAddress: Int { get set }
    var mUpperAddress: Int { get set }
    var ramBuffer: [UInt8] { get set }
    var ramPointer: Int { get set }
    var ramBufferPointer: Int { get set }
    var ramBufferPointer2	: Int { get set }
    var checksumApp0: Int { get set }
    var checksumApp1: Int { get set }
    var mDataSizeApp0: Int { get set }
    var mDataSizeApp1: Int { get set }

    // Characteristics
    var toshibaSoftwareRevisionCharateristic: CBCharacteristic? { get set }
    var toshibaHardwareRevisionCharateristic: CBCharacteristic? { get set }
    var toshibaVersionCheckCharacteristic: CBCharacteristic? { get set }
    var toshibaOpenFlashCharacteristic: CBCharacteristic? { get set }
    var toshibaCheckflagCharacteristic: CBCharacteristic? { get set }
    var toshibaProcessEraseCharacteristic: CBCharacteristic? { get set }
    var toshibaMemoryWriteCharacteristic: CBCharacteristic? { get set }
    var toshibaChecksum1Characteristic: CBCharacteristic? { get set }
    var toshibaChecksum2Characteristic: CBCharacteristic? { get set }
    var toshibaFlagChangeCharacteristic: CBCharacteristic? { get set }
    var toshibaCloseFlashCharacteristic: CBCharacteristic? { get set }

    // Completion
    var toshibaOTACompletion: ((Result<Void, PBFirmwareUpdateError>) -> Void)? { get set }

    // Variables
    var imageToOTA: Data { get set }
    var imageToOTASize: Int { get set }

    
    /// Runs the OTA update to install a hex image into the chip.
    /// - Parameters:
    ///   - image: the image that should be installed, in binary (Data type).
    ///   - completion: Completion block that will be executed once finished.
    func runToshibaOTA(image: Data, completion: @escaping (Result<Void, PBFirmwareUpdateError>) -> Void)
    
    // Inner Functions
    func setFilePointer(pointer: Int)
    func setRamBuffer(buffer: [UInt8])
    func setRamBufferAtIndex(byte: UInt8, index: Int)
    func setRamPointer(pointer: Int)
    func setRamBufferPointer(pointer: Int)
    func setRamBufferPointer2(pointer: Int)
    func setUpperAddress(mUpperAddress: Int)
    func setChecksumApp0(checksum: Int)
    func setChecksumApp1(checksum: Int)
    func setDataSizeApp0(dataSize: Int)
    func setDataSizeApp1(dataSize: Int)
    func setWriteProcessStep(step: ToshibaWriteMainProcessStep)
}

// MARK: - PBBluetoothUpdatableDevice Implementation

extension PBToshibaChipProtocol where Self: PBDevice {
    
    // Version Check
    
    internal func writeVersionCheck() {
        guard let characteristic = toshibaVersionCheckCharacteristic, let connectivity = self.connectionState, connectivity == .connected else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes = [UInt8(0x32), UInt8(0x2e), UInt8(0x30)]
        
        let bytePointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        print("w version check \(bytes)")
        
        firmwareUpdateProgress.send(1)
        
        self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // Open Memory
    
    internal func openMemory() {
        guard let characteristic = toshibaOpenFlashCharacteristic, let connectivity = self.connectionState, connectivity == .connected else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes = [UInt8(0x01), UInt8(0x00), UInt8(0x00), UInt8(0x00), UInt8(0x00)]
        
        let bytePointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            DispatchQueue.main.async {[weak self] in
                self?.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            }
            
            return
        }
        
        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        print("w open memory \(bytes)")
        
        firmwareUpdateProgress.send(2)
        
        DispatchQueue.main.async {
            self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    // Write Checkflag
    
    internal func writeFlagRead() {
        guard let characteristic = toshibaCheckflagCharacteristic, let connectivity = self.connectionState, connectivity == .connected else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes: [UInt8] = [UInt8.init(truncating: NSNumber(value: BOOT_AREA_FLAG_ADDRESS >> 24)),
                             UInt8.init(truncating: NSNumber(value: BOOT_AREA_FLAG_ADDRESS >> 16)),
                             UInt8.init(truncating: NSNumber(value: BOOT_AREA_FLAG_ADDRESS >> 8)),
                             UInt8.init(truncating: NSNumber(value: BOOT_AREA_FLAG_ADDRESS)),
                             UInt8.init(truncating: NSNumber(value: TOSHIBA_FLAG_AREA_SIZE >> 24)),
                             UInt8.init(truncating: NSNumber(value: TOSHIBA_FLAG_AREA_SIZE >> 16)),
                             UInt8.init(truncating: NSNumber(value: TOSHIBA_FLAG_AREA_SIZE >> 8)),
                             UInt8.init(truncating: NSNumber(value: TOSHIBA_FLAG_AREA_SIZE))]
        
        let bytePointer: UnsafePointer<UInt8>? = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))

            return
        }

        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        print("w flag read \(bytes)")
        
        firmwareUpdateProgress.send(3)

        DispatchQueue.main.async {
            self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    // Write Process Erase
    
    internal func writeProcessErase(step: ToshibaProcessEraseStep) {
        guard let characteristic = toshibaProcessEraseCharacteristic, let connectivity = self.connectionState, connectivity == .connected else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        var bytes: [UInt8] = []
        
        switch step {
        case .header:
            bytes = [UInt8.init(truncating: NSNumber(value: TARGET_AREA_HEADER_START_ADDRESS >> 24)),
                     UInt8.init(truncating: NSNumber(value: TARGET_AREA_HEADER_START_ADDRESS >> 16)),
                     UInt8.init(truncating: NSNumber(value: TARGET_AREA_HEADER_START_ADDRESS >> 8)),
                     UInt8.init(truncating: NSNumber(value: TARGET_AREA_HEADER_START_ADDRESS))]
        case .app0, .app1:
            bytes = [UInt8.init(truncating: NSNumber(value: erasingAddress >> 24)),
                     UInt8.init(truncating: NSNumber(value: erasingAddress >> 16)),
                     UInt8.init(truncating: NSNumber(value: erasingAddress >> 8)),
                     UInt8.init(truncating: NSNumber(value: erasingAddress))]
        }
        
        let bytePointer: UnsafePointer<UInt8>? = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))

            return
        }

        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        print("w process erase \(bytes)")
        
        firmwareUpdateProgress.send(10)

        DispatchQueue.main.async {
            self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    // Write Main Process
    
    internal func writeMainProcess() {
        guard let linesString = String(data: imageToOTA, encoding: .utf8) else {
            self.toshibaOTACompletion?(.failure(.corruptedImage))
            
            return
        }
        
        let linesArray = linesString.replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: ":", with: "").components(separatedBy: "\n")
        
        if writeProcessStep == .analysis {
            setRamBuffer(buffer: [UInt8].init(repeating: 0, count: 4096))
            setRamBufferPointer(pointer: 0)
            setRamBufferPointer2(pointer: 0)
            setRamPointer(pointer: 0)
            var analysisState: WriteAnalytisState = .start
            
            while analysisState != .end {
                guard let readBuff: [UInt8] = stringToByteArray(string: linesArray[filePointer]) else {
                    self.toshibaOTACompletion?(.failure(.corruptedImage))
                    
                    return
                }
                
                guard isOk1LineChecksum(bytes: readBuff) else {
                    self.toshibaOTACompletion?(.failure(.corruptedImage))
                    
                    return
                }
                
                guard readBuff.count > 0 else {
                    writeForChecksum1A()
                    
                    return
                }
                
                setFilePointer(pointer: filePointer+1)
                
                if readBuff[3] == 0x00 { // Data
                    if analysisState == .start {
                        setRamPointer(pointer: ((mUpperAddress << 16) & 0x00ff0000) | ((Int(readBuff[1]) << 8) & 0x0000ff00) | (Int(readBuff[2]) & 0x000000ff))
                        setRamBufferPointer(pointer: Int(readBuff[0]))
                        
                        if ramPointer < RAM_APP1_TOP_ADDRESS {
                            for index in 0..<readBuff[0] {
                                setRamBufferAtIndex(byte: readBuff[4 + Int(index)], index: Int(index))
                                let temp = readBuff[4 + Int(index)]
                                setChecksumApp0(checksum: checksumApp0 + (Int(temp) & 0xFF))
                                setDataSizeApp0(dataSize: mDataSizeApp0 + 1)
                            }
                        } else {
                            for index in 0..<readBuff[0] {
                                setRamBufferAtIndex(byte: readBuff[4 + Int(index)], index: Int(index))
                                let temp = readBuff[4 + Int(index)]
                                setChecksumApp1(checksum: checksumApp1 + (Int(temp) & 0xFF))
                                setDataSizeApp1(dataSize: mDataSizeApp1 + 1)
                            }
                        }
                        
                        analysisState = .running
                    } else {
                        setRamBufferPointer(pointer: ((mUpperAddress << 16) & 0x00ff0000) | ((Int(readBuff[1]) << 8) & 0x0000ff00) | (Int(readBuff[2]) & 0x000000ff))
                        setRamBufferPointer(pointer: ramBufferPointer - ramPointer)
                        
                        if ramPointer < RAM_APP1_TOP_ADDRESS {
                            for index in 0..<readBuff[0] {
                                setRamBufferAtIndex(byte: readBuff[4 + Int(index)], index: ramBufferPointer)
                                setRamBufferPointer(pointer: ramBufferPointer + 1)
                                let temp = readBuff[4 + Int(index)]
                                setChecksumApp0(checksum: checksumApp0 + (Int(temp) & 0xFF))
                                setDataSizeApp0(dataSize: mDataSizeApp0 + 1)
                            }
                        } else {
                            for index in 0..<readBuff[0] {
                                setRamBufferAtIndex(byte: readBuff[4 + Int(index)], index: ramBufferPointer)
                                setRamBufferPointer(pointer: ramBufferPointer + 1)
                                let temp = readBuff[4 + Int(index)]
                                setChecksumApp1(checksum: checksumApp1 + (Int(temp) & 0xFF))
                                setDataSizeApp1(dataSize: mDataSizeApp1 + 1)
                            }
                        }
                        
                        if 4096 - ramBufferPointer < 16 {
                            analysisState = .end
                            setWriteProcessStep(step: .write)
                        }
                    }
                } else if readBuff[3] == 0x04 { // Extended line
                    setUpperAddress(mUpperAddress: Int(readBuff[5]))
                    if (readBuff[5] < (RAM_APP0_TOP_ADDRESS >> 16)) || (readBuff[5] > (RAM_APP0_END_ADDRESS >> 16)) {
                        analysisState = .end
                        setWriteProcessStep(step: .write)
                    }
                } else if readBuff[3] == 0x01 { // End of File
                    analysisState = .end
                    
                    guard ramBufferPointer != 0 else {
                        writeForChecksum1A()
                        
                        return
                    }
                    
                    setWriteProcessStep(step: .write)
                }
            }
        }
        
        if writeProcessStep == .write {
            guard let characteristic = toshibaMemoryWriteCharacteristic, let connectivity = self.connectionState, connectivity == .connected else {
                self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
                
                return
            }
            
            var flashAddress: Int
            
            if ramPointer < RAM_APP1_TOP_ADDRESS {
                flashAddress = TARGET_AREA_APP0_START_ADDRESS + ramPointer - RAM_APP0_TOP_ADDRESS
            } else {
                flashAddress = TARGET_AREA_APP1_START_ADDRESS + ramPointer - RAM_APP1_TOP_ADDRESS
            }
            
            if ramBufferPointer - ramBufferPointer2 >= 0x10 {
                var chunkToWrite: [UInt8] = [UInt8].init(repeating: 0, count: 20)
                flashAddress = flashAddress + ramBufferPointer2
                
                guard !addressOverflows(address: flashAddress) else {
                    self.toshibaOTACompletion?(.failure(.errorWritingOnOverflowdedAddress))
                    
                    return
                }
                
                chunkToWrite[0] = UInt8.init(truncating: NSNumber(value: flashAddress >> 24))
                chunkToWrite[1] = UInt8.init(truncating: NSNumber(value: flashAddress >> 16))
                chunkToWrite[2] = UInt8.init(truncating: NSNumber(value: flashAddress >> 8))
                chunkToWrite[3] = UInt8.init(truncating: NSNumber(value: flashAddress))
                
                chunkToWrite[4...19] = ramBuffer[ramBufferPointer2...ramBufferPointer2+0x0F]
                
                setRamBufferPointer2(pointer: ramBufferPointer2 + 0x010)
                
                if ramBufferPointer == ramBufferPointer2 {
                    setWriteProcessStep(step: .analysis)
                }
                
                let bytePointer: UnsafePointer<UInt8>? = chunkToWrite.withUnsafeBufferPointer { $0.baseAddress }
                
                guard let unwrappedPointer = bytePointer else {
                    self.toshibaOTACompletion?(.failure(.couldntConnectDevice))

                    return
                }

                let data = Data(bytes: unwrappedPointer, count: chunkToWrite.count * MemoryLayout<UInt8>.size)

                print("w main write \(chunkToWrite)")
                
                firmwareUpdateProgress.send(10 + Int(filePointer * 80 / linesArray.count))
                
                DispatchQueue.main.async {
                    self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                }
            } else if ramBufferPointer != ramBufferPointer2 {
                var chunkToWrite: [UInt8] = [UInt8].init(repeating: 0, count: 4 + ramBufferPointer - ramBufferPointer2)
                flashAddress = flashAddress + ramBufferPointer2
                
                guard !addressOverflows(address: flashAddress) else {
                    self.toshibaOTACompletion?(.failure(.errorWritingOnOverflowdedAddress))
                    
                    return
                }
                
                chunkToWrite[0] = UInt8.init(truncating: NSNumber(value: flashAddress >> 24))
                chunkToWrite[1] = UInt8.init(truncating: NSNumber(value: flashAddress >> 16))
                chunkToWrite[2] = UInt8.init(truncating: NSNumber(value: flashAddress >> 8))
                chunkToWrite[3] = UInt8.init(truncating: NSNumber(value: flashAddress))
                
                chunkToWrite[4...4 + ramBufferPointer - ramBufferPointer2 - 1] = ramBuffer[ramBufferPointer2...ramBufferPointer - 1]
                
                setRamBufferPointer2(pointer: ramBufferPointer)
                
                let bytePointer: UnsafePointer<UInt8>? = chunkToWrite.withUnsafeBufferPointer { $0.baseAddress }
                
                guard let unwrappedPointer = bytePointer else {
                    self.toshibaOTACompletion?(.failure(.couldntConnectDevice))

                    return
                }

                let data = Data(bytes: unwrappedPointer, count: chunkToWrite.count * MemoryLayout<UInt8>.size)

                print("w main write \(chunkToWrite)")
                
                firmwareUpdateProgress.send(10 + Int(filePointer * 80 / linesArray.count))
                
                DispatchQueue.main.async {
                    self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                }
            }
        }
    }
    
    // Checksum 1A
    
    func writeForChecksum1A() {
        guard let characteristic = toshibaChecksum1Characteristic, let connectivity = self.connectionState, connectivity == .connected else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes = [UInt8.init(truncating: NSNumber(value: TARGET_AREA_APP0_START_ADDRESS >> 24)),
                     UInt8.init(truncating: NSNumber(value: TARGET_AREA_APP0_START_ADDRESS >> 16)),
                     UInt8.init(truncating: NSNumber(value: TARGET_AREA_APP0_START_ADDRESS >> 8)),
                     UInt8.init(truncating: NSNumber(value: TARGET_AREA_APP0_START_ADDRESS)),
                     UInt8.init(truncating: NSNumber(value: mDataSizeApp0 >> 24)),
                     UInt8.init(truncating: NSNumber(value: mDataSizeApp0 >> 16)),
                     UInt8.init(truncating: NSNumber(value: mDataSizeApp0 >> 8)),
                     UInt8.init(truncating: NSNumber(value: mDataSizeApp0))]
        
        let bytePointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            DispatchQueue.main.async {[weak self] in
                self?.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            }
            
            return
        }
        
        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        print("w checksum1 \(bytes)")
        
        firmwareUpdateProgress.send(92)
        
        DispatchQueue.main.async {
            self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    // Checksum 1B
    
    func writeForChecksum1B() {
        guard let characteristic = toshibaChecksum1Characteristic, let connectivity = self.connectionState, connectivity == .connected else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes = [UInt8.init(truncating: NSNumber(value: TARGET_AREA_APP1_START_ADDRESS >> 24)),
                     UInt8.init(truncating: NSNumber(value: TARGET_AREA_APP1_START_ADDRESS >> 16)),
                     UInt8.init(truncating: NSNumber(value: TARGET_AREA_APP1_START_ADDRESS >> 8)),
                     UInt8.init(truncating: NSNumber(value: TARGET_AREA_APP1_START_ADDRESS)),
                     UInt8.init(truncating: NSNumber(value: mDataSizeApp1 >> 24)),
                     UInt8.init(truncating: NSNumber(value: mDataSizeApp1 >> 16)),
                     UInt8.init(truncating: NSNumber(value: mDataSizeApp1 >> 8)),
                     UInt8.init(truncating: NSNumber(value: mDataSizeApp1))]
        
        let bytePointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            DispatchQueue.main.async {[weak self] in
                self?.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            }
            
            return
        }
        
        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        print("w checksum2 \(bytes)")
        
        firmwareUpdateProgress.send(94)
        
        DispatchQueue.main.async {
            self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    // End 1
    
    func writeEnd1() {
        guard let characteristic = toshibaMemoryWriteCharacteristic, let connectivity = self.connectionState, connectivity == .connected else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes = [UInt8.init(truncating: NSNumber(value: TARGET_AREA_HEADER_START_ADDRESS >> 24)),
                     UInt8.init(truncating: NSNumber(value: TARGET_AREA_HEADER_START_ADDRESS >> 16)),
                     UInt8.init(truncating: NSNumber(value: TARGET_AREA_HEADER_START_ADDRESS >> 8)),
                     UInt8.init(truncating: NSNumber(value: TARGET_AREA_HEADER_START_ADDRESS)),
                     UInt8.init(truncating: NSNumber(value: mDataSizeApp0 >> 24)),
                     UInt8.init(truncating: NSNumber(value: mDataSizeApp0 >> 16)),
                     UInt8.init(truncating: NSNumber(value: mDataSizeApp0 >> 8)),
                     UInt8.init(truncating: NSNumber(value: mDataSizeApp0)),
                     UInt8.init(truncating: NSNumber(value: checksumApp0 >> 24)),
                     UInt8.init(truncating: NSNumber(value: checksumApp0 >> 16)),
                     UInt8.init(truncating: NSNumber(value: checksumApp0 >> 8)),
                     UInt8.init(truncating: NSNumber(value: checksumApp0)),
                     UInt8(0x10),
                     UInt8(0x48),
                     UInt8(0x55),
                     UInt8(0xAA),
                     UInt8.init(truncating: NSNumber(value: (TARGET_AREA_APP0_START_ADDRESS / 0x1000) >> 8)),
                     UInt8.init(truncating: NSNumber(value: (TARGET_AREA_APP0_START_ADDRESS / 0x1000))),
                     UInt8(0x00),
                     UInt8(0x00)]
        
        let bytePointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            DispatchQueue.main.async {[weak self] in
                self?.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            }
            
            return
        }
        
        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        print("w end1 \(bytes)")
        
        firmwareUpdateProgress.send(96)
        
        DispatchQueue.main.async {
            self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    // End 2
    
    func writeEnd2() {
        guard let characteristic = toshibaMemoryWriteCharacteristic, let connectivity = self.connectionState, connectivity == .connected else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes = [UInt8.init(truncating: NSNumber(value: (TARGET_AREA_HEADER_START_ADDRESS + 0x0010) >> 24)),
                     UInt8.init(truncating: NSNumber(value: (TARGET_AREA_HEADER_START_ADDRESS + 0x0010) >> 16)),
                     UInt8.init(truncating: NSNumber(value: (TARGET_AREA_HEADER_START_ADDRESS + 0x0010) >> 8)),
                     UInt8.init(truncating: NSNumber(value: (TARGET_AREA_HEADER_START_ADDRESS + 0x0010))),
                     UInt8(0x00),
                     UInt8(0x00),
                     UInt8(0x00),
                     UInt8(0x00),
                     UInt8(0x00),
                     UInt8(0x00),
                     UInt8(0x00),
                     UInt8(0x00),
                     UInt8(0x00),
                     UInt8(0x00),
                     UInt8(0x00),
                     UInt8(0x00),
                     UInt8(0x00),
                     UInt8(0x00)]
        
        let bytePointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            DispatchQueue.main.async {[weak self] in
                self?.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            }
            
            return
        }
        
        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        print("w end2 \(bytes)")
        
        firmwareUpdateProgress.send(98)
        
        DispatchQueue.main.async {
            self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    // Flag change
    
    func writeFlagChange() {
        guard let characteristic = toshibaFlagChangeCharacteristic, let connectivity = self.connectionState, connectivity == .connected else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes = [UInt8.init(truncating: NSNumber(value: BOOT_AREA_FLAG_ADDRESS >> 24)),
                     UInt8.init(truncating: NSNumber(value: BOOT_AREA_FLAG_ADDRESS >> 16)),
                     UInt8.init(truncating: NSNumber(value: BOOT_AREA_FLAG_ADDRESS >> 8)),
                     UInt8.init(truncating: NSNumber(value: BOOT_AREA_FLAG_ADDRESS)),
                     UInt8.init(truncating: NSNumber(value: TOSHIBA_FLAG_AREA_SIZE >> 24)),
                     UInt8.init(truncating: NSNumber(value: TOSHIBA_FLAG_AREA_SIZE >> 16)),
                     UInt8.init(truncating: NSNumber(value: TOSHIBA_FLAG_AREA_SIZE >> 8)),
                     UInt8.init(truncating: NSNumber(value: TOSHIBA_FLAG_AREA_SIZE)),
                     UInt8(MEMORY_SIDE_TO_WRITE == .sideA ? 0x00 : 0x01)]
        
        let bytePointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            DispatchQueue.main.async {[weak self] in
                self?.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            }
            
            return
        }
        
        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        print("w flag change \(bytes)")
        
        firmwareUpdateProgress.send(99)
        
        DispatchQueue.main.async {
            self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    // Close Memory
    
    internal func closeMemory() {
        guard let characteristic = toshibaCloseFlashCharacteristic, let connectivity = self.connectionState, connectivity == .connected else {
            self.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            
            return
        }
        
        let bytes = [UInt8(0x01)]
        
        let bytePointer = bytes.withUnsafeBufferPointer { $0.baseAddress }
        
        guard let unwrappedPointer = bytePointer else {
            DispatchQueue.main.async {[weak self] in
                self?.toshibaOTACompletion?(.failure(.couldntConnectDevice))
            }
            
            return
        }
        
        let data = Data(bytes: unwrappedPointer, count: bytes.count * MemoryLayout<UInt8>.size)
        
        print("w close memory \(bytes)")
        
        firmwareUpdateProgress.send(100)
        
        DispatchQueue.main.async {
            self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
}

// MARK: - Utils

extension PBToshibaChipProtocol {
    
    func stringToByteArray(string: String) -> [UInt8]? {
        let length = string.count
        
        if length & 1 != 0 {
            return nil
        }
        
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        
        var index = string.startIndex
        
        for _ in 0..<length/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            if let byte = UInt8(string[index..<nextIndex], radix: 16) {
                bytes.append(byte)
            } else {
                return nil
            }
            index = nextIndex
        }
        
        return bytes
    }
    
    func isOk1LineChecksum(bytes: [UInt8]) -> Bool {
        var sum = 0
        
        for byte in bytes {
            sum += Int(byte) & 0xff
        }
        
        sum &= 0xff
        
        return sum == 0
    }
    
    private func addressOverflows(address: Int) -> Bool {
        if MEMORY_SIDE_TO_WRITE == .sideA {
            if address >= FLASH_A_APP0_TOP_ADDRESS && address <= (FLASH_A_APP0_TOP_ADDRESS + FLASH_APP0_SIZE) {
                return false
            } else if address >= FLASH_A_APP1_TOP_ADDRESS && address <= (FLASH_A_APP1_TOP_ADDRESS + FLASH_APP1_SIZE) {
                return false
            }
        } else {
            if address >= FLASH_B_APP0_TOP_ADDRESS && address <= (FLASH_B_APP0_TOP_ADDRESS + FLASH_APP0_SIZE) {
                return false
            } else if address >= FLASH_B_APP1_TOP_ADDRESS && address <= (FLASH_B_APP1_TOP_ADDRESS + FLASH_APP1_SIZE) {
                return false
            }
        }
        
        return true
    }
    
}
