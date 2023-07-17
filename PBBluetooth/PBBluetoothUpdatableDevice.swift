//
//  PBBluetoothUpdatableDevice.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 28/01/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import UIKit
import Combine

public protocol PBBluetoothUpdatableDevice {
    
    /// Indicates the OTA update progress, ranging from 0 to 100.
    var firmwareUpdateProgress: CurrentValueSubject<Int, Never> { get }
    
    /// Updates the firmware of the device with the give image.
    /// - Parameter image: The binary image which contains the new firmware.
    /// - Parameter completion: The completion block that receives a Result that is a Void on success or an PBBluetoothError on failure
    func runOTA(image: Data, completion: @escaping (Result<Void, PBFirmwareUpdateError>) -> Void)
    
    /// Gets the firmware version of the device in String format, or an Error
    /// - Parameter completion: The completion block that receives a Result that is a String on success or an PBBluetoothError on failure
    func getFirmwareVersion(completion: @escaping (Result<String, PBBluetoothError>) -> Void)
    
    /// Verifies the firmware installed is running correctly by checking the hardware revision
    /// - Parameter completion: The completion block that receives a Result that is a Bool indicating the correct status of the firmware or a PBBluetoothError on failure
    func verifyHardwareRevision(completion: @escaping (Result<Bool, PBBluetoothError>) -> Void)
    
}
