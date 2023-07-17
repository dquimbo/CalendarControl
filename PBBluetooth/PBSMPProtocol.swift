//
//  PBSMPDevice.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 09/11/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import UIKit
import iOSMcuManagerLibrary
import Combine

public protocol PBSMPProtocol: PBBluetoothUpdatableDevice {
    
    // Variables
    
    var firmwareUpdateCompletion: ((Result<Void, PBFirmwareUpdateError>) -> Void)? { get set }
    
    var firmwareUpdateProgress: CurrentValueSubject<Int, Never> { get }
        
    // Functions
    
    func smpReadImageSlots(callback: @escaping McuMgrCallback<McuMgrImageStateResponse>)
    
    func smpUploadImage(data: Data, callback: @escaping (Result<Void, Error>) -> Void)
    
    func smpConfirmImageSlot(hash: [UInt8], callback: @escaping McuMgrCallback<McuMgrResponse>)
    
    func smpEraseImageSlot(callback: @escaping McuMgrCallback<McuMgrResponse>)
    
    func smpReset(callback: @escaping McuMgrCallback<McuMgrResponse>)


}

extension PBSMPProtocol where Self: PBDevice, Self: FirmwareUpgradeDelegate, Self: ImageUploadDelegate {
    
    internal func startFirmwareUpdate(data: Data) {
        guard let peripheral = self.peripheral else { return }
        
        let bleTransport = McuMgrBleTransport(peripheral)
        
        let manager = FirmwareUpgradeManager(transporter: bleTransport, delegate: self)
        manager.mode = .confirmOnly
        
        do {
            try manager.start(data: data)
        } catch {
            firmwareUpdateCompletion?(.failure(.couldntConnectDevice))
        }
    }
    
    // MARK: - SMP Functions
    
    internal func readImageSlots(callback: @escaping McuMgrCallback<McuMgrImageStateResponse>) {
        guard let peripheral = self.peripheral else {
            return
        }

        let bleTransport = McuMgrBleTransport(peripheral)
        let manager = ImageManager(transporter: bleTransport)

        manager.list(callback: callback)
    }
    
    internal func uploadImage(data: Data) {
        guard let peripheral = self.peripheral else {
            return
        }
        
        let bleTransport = McuMgrBleTransport(peripheral)
        
        let manager = FirmwareUpgradeManager(transporter: bleTransport, delegate: self)
        try? manager.start(data: data)
    }
    
    internal func confirmImageSlot(hash: [UInt8], callback: @escaping McuMgrCallback<McuMgrResponse>) {
        guard let peripheral = self.peripheral else {
            return
        }
        
        let bleTransport = McuMgrBleTransport(peripheral)
        let manager = ImageManager(transporter: bleTransport)
        
        manager.confirm(hash: hash, callback: callback)
    }
    
    internal func eraseImageSlot(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        guard let peripheral = self.peripheral else {
            return
        }

        let bleTransport = McuMgrBleTransport(peripheral)
        
        let manager = ImageManager(transporter: bleTransport)
        manager.erase(callback: callback)
    }
    
    internal func reset(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        guard let peripheral = self.peripheral else {
            return
        }
        
        let bleTransport = McuMgrBleTransport(peripheral)
        let manager = DefaultManager(transporter: bleTransport)
        
        manager.reset(callback: callback)
    }
    
}
