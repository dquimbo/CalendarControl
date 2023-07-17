//
//  PBBondableDeviceProtocol.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 21/03/2022.
//  Copyright © 2022 Nick Franks. All rights reserved.
//

import UIKit

public enum PBBondingState: UInt8 {
    case bonded = 0x00
    case unbonded = 0x01
    case unknown = 0xFF
}

public enum PBBondTriggerResult {
    case success
    case passwordRequired
    case passwordNotAccepted
    case deviceButtonPressRequired
    case error(PBBluetoothError)
}

public protocol PBBondableDeviceProtocol {
    
    /// This function triggers a bond request from the device. It may or may not require a password.
    /// - Parameters:
    ///   - password: The password to access owner mode of the device, prior to request the bonding.
    ///   - completion: The completion block that returns Void on success and a PBBondTriggerError when failure.
    func triggerBondFromDevice(password: Data?, completion: @escaping (PBBondTriggerResult) -> Void)
    
    /// Resets the device. Removes any bonding information.
    /// - Parameter completion: The completion block that returns Void on success and a PBBluetoothError when failure.
    func factoryResetDevice(completion: @escaping (Result<Void, PBBluetoothError>) -> Void)
    
}
