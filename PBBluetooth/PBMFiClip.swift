//
//  MFiCard.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 21/03/2022.
//  Copyright © 2022 Nick Franks. All rights reserved.
//

import iOSMcuManagerLibrary
import Combine
import Foundation
import CoreBluetooth

public class PBMFiClip: PBMFiDevice {
    
    /// Buzzing variables
    internal var needToBuzz = false
    internal var buzzCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    internal var needToStopBuzz = false
    internal var stopBuzzCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    
    /// Bonding variables
    internal var bonding = false
    internal var bondCompletion: ((PBBondTriggerResult) -> Void)?
    
    /// Ceaning bond information
    private var factoryResetting = false
    private var factoryResetCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    
    /// SMP variables
    public var smpUploadImageCompletion: ((Result<Void, Error>) -> Void)?
    public var firmwareUpdateCompletion: ((Result<Void, PBFirmwareUpdateError>) -> Void)?
    private var startingOTA: Bool = false
    private var firmwareUpdateImage: Data? = nil
    public var firmwareUpdateProgress: CurrentValueSubject<Int, Never> = CurrentValueSubject<Int, Never>(0)
    
    // Timer to controle timeout
    private var requestTimer: Timer?
    
    /// Characteristics
    internal var data1Characteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.bonding {
                    self.readForBonding()
                } else if self.factoryResetting {
                    self.writeToFactoryReset()
                } else if self.startingOTA, let image = self.firmwareUpdateImage {
                    self.startFirmwareUpdate(data: image)
                }
            }
        }
    }
    
    internal var data2Characteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.needToBuzz {
                    self.writeForBuzz()
                } else if self.needToStopBuzz {
                    self.writeForStopBuzz()
                }
            }
        }
    }
    
    /// Methods
    
    override init(withMacAddress address: String) {
        super.init(withMacAddress: address)
        
        self.deviceType = .mfiClip
        self.dataParser = PBMFiClipAdvertisementParser()
    }
    
    override public func discoverServices() {
        self.peripheral?.discoverServices([finderServiceUUID])
    }
    
    // MARK: -  CBPeripheralDelegate
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            switch service.uuid {
            case finderServiceUUID:
                peripheral.discoverCharacteristics([data1CharacteristicUUID, data2CharacteristicUUID], for: service)
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
            case data1CharacteristicUUID:
               break
            case data2CharacteristicUUID:
                if let _ = error {
                    self.buzzCompletion?(.failure(.errorWrittingInCharacteristic))
                    self.stopBuzzCompletion?(.failure(.errorWrittingInCharacteristic))
                } else if self.needToBuzz {
                    self.needToBuzz = false
                    self.buzzCompletion?(.success(()))
                } else if self.needToStopBuzz {
                    self.needToStopBuzz = false
                    self.stopBuzzCompletion?(.success(()))
                }
            default:
                return
            }
        }
    }
    
    /// Triggers the bonding method from the device
    /// - Parameter completion: Void on success and PBBluetoothError on failure
    public func triggerBondFromDevice(password: Data?, completion: @escaping (PBBondTriggerResult) -> Void) {
        self.bondCompletion = completion
        self.bonding = true
        
        guard let state = self.connectionState else {
            bondCompletion?(.error(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            bondCompletion?(.error(.couldntConnectDevice))
        case .connected:
            readForBonding()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.bondCompletion?(.error(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            bondCompletion?(.error(.couldntDetermineDeviceState))
        }
    }
    
    public func getBatteryPercentage(withManufacturerData data: Data) -> Double? {
        guard data.count > 3 else { return nil }
        
        return Double(data[3])
    }

}

// MARK: - PBBluetoothDevice

extension PBMFiClip: PBBluetoothDevice {
    
    /// Buzzing
    /// - Parameter completion: A completion that is Void on success and PBBluetoothError on failure
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
    
    internal func writeForBuzz() {
        guard self.needToBuzz, let characteristic = self.data2Characteristic else {
            self.buzzCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        self.peripheral?.writeValue(Data([0x01]), for: characteristic, type: .withoutResponse)
        
        self.needToBuzz = false
        
        self.buzzCompletion?(.success(()))
    }
    
    
    /// Stopping the buzz
    /// - Parameter completion: A completion that is Void on success and PBBluetoothError on failure
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
    
    internal func writeForStopBuzz() {
        guard self.needToStopBuzz, let characteristic = self.data2Characteristic else {
            self.stopBuzzCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        self.peripheral?.writeValue(Data([0x02]), for: characteristic, type: .withoutResponse)
        
        self.needToStopBuzz = false
        
        self.stopBuzzCompletion?(.success(()))
    }
    
    public func setBuzzVolume(volume: PBDeviceVolume, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        completion(.failure(.featureNotAvailableInFirmware))
    }
    
    public func setInDormantMode(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        completion(.failure(.featureNotAvailableInFirmware))
    }
    
}

// MARK: - PBBondableDeviceProtocol

extension PBMFiClip: PBBondableDeviceProtocol {
    
    internal func readForBonding() {
        guard self.bonding,
              let characteristic = self.data1Characteristic,
              let peripheral = self.peripheral else {
                  self.bondCompletion?(.error(.couldntConnectDevice))
                  return
              }
        
        peripheral.readValue(for: characteristic)
        
        self.bonding = false
        
        self.bondCompletion?(.success)
    }
    
    /// Cleans the bonding information from the device, NOT FROM THE PHONE
    /// - Parameter completion: Void on success and PBBluetoothError on failure
    public func factoryResetDevice(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.factoryResetCompletion = completion
        self.factoryResetting = true
        
        guard let state = self.connectionState else {
            factoryResetting = false
            factoryResetCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        self.requestTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { _ in
            self.factoryResetCompletion?(.failure(.requestTimedOut))
        })
        
        switch state {
        case .connecting, .disconnecting:
            factoryResetCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeToFactoryReset()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.factoryResetCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            factoryResetCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    private func writeToFactoryReset() {
        guard self.factoryResetting,
              let characteristic = self.data1Characteristic,
              let peripheral = self.peripheral else {
                  self.factoryResetCompletion?(.failure(.couldntConnectDevice))
                  return
              }
        
        self.requestTimer?.invalidate()
        self.requestTimer = nil
        
        peripheral.writeValue(Data([0x04]), for: characteristic, type: .withoutResponse)
        
        self.factoryResetting = false
        
        self.factoryResetCompletion?(.success(()))
    }
    
}

// MARK: - OTA update functions

extension PBMFiClip: PBSMPProtocol, PBBluetoothUpdatableDevice, FirmwareUpgradeDelegate, ImageUploadDelegate {
    
    // MARK: - PBBluetoothUpdatableDevice
    
    public func getFirmwareVersion(completion: @escaping (Result<String, PBBluetoothError>) -> Void) {
        readImageSlots { response, error in
            if let data = response, data.isSuccess(), let images = data.images {
                for image in images {
                    if image.active {
                        completion(.success(image.version))
                        
                        break
                    }
                }
            } else {
                completion(.failure(.couldntConnectDevice))
            }
        }
    }
    
    public func runOTA(image: Data, completion: @escaping (Result<Void, PBFirmwareUpdateError>) -> Void) {
        firmwareUpdateCompletion = { result in
            DispatchQueue.main.async {
                self.firmwareUpdateProgress.send(0)
                
                switch result {
                case .success():
                    completion(.success(()))
                case .failure(let error):
                    self.firmwareUpdateImage = nil
                    
                    completion(.failure(error))
                }
            }
        }
        
        firmwareUpdateImage = image
        startingOTA = true
        
        guard let state = self.connectionState else {
            firmwareUpdateCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            firmwareUpdateCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            startingOTA = false
            startFirmwareUpdate(data: image)
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.firmwareUpdateCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            firmwareUpdateCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    public func verifyHardwareRevision(completion: @escaping (Result<Bool, PBBluetoothError>) -> Void) {
        readImageSlots { response, error in
            if let data = response, data.isSuccess(), let images = data.images {
                for image in images {
                    if image.active {
                        completion(.success(true))
                        
                        break
                    }
                }
                
                completion(.success(false))
            } else {
                completion(.failure(.couldntConnectDevice))
            }
        }
    }
    
    // MARK: - PBSMPProtocol
    
    public func smpReadImageSlots(callback: @escaping McuMgrCallback<McuMgrImageStateResponse>) {
        readImageSlots(callback: callback)
    }
    
    public func smpUploadImage(data: Data, callback: @escaping (Result<Void, Error>) -> Void) {
        smpUploadImageCompletion = callback
            
        uploadImage(data: data)
    }
    
    public func smpConfirmImageSlot(hash: [UInt8], callback: @escaping McuMgrCallback<McuMgrResponse>) {
        confirmImageSlot(hash: hash, callback: callback)
    }
    
    public func smpEraseImageSlot(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        eraseImageSlot(callback: callback)
    }
    
    public func smpReset(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        reset(callback: callback)
    }
    
    // MARK: - FirmwareUpgradeDelegate
    
    public func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        firmwareUpdateProgress.send(Int(Float(bytesSent) * 100 / Float(imageSize)))
    }
    
    public func upgradeDidComplete() {
        firmwareUpdateCompletion?(.success(()))
    }
    
    public func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
        firmwareUpdateCompletion?(.failure(.couldntConnectDevice))
    }
    
    /// Unused for now
    public func upgradeDidStart(controller: FirmwareUpgradeController) { }
    
    /// Unused for now
    public func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) { }
    
    /// Unused for now
    public func upgradeDidCancel(state: FirmwareUpgradeState) { }
    
    // MARK: - ImageUploadDelegate
    
    public func uploadDidFail(with error: Error) {
        smpUploadImageCompletion?(.failure(error))
    }
    
    public func uploadDidFinish() {
        smpUploadImageCompletion?(.success(()))
    }
    
    /// Unused for now
    public func uploadDidCancel() { }
}
