//
//  PBBluetoothDevice.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 28/01/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import UIKit


/// This is the basic protocol of a Pebblebee device that connects through Bluetooh, in the future the idea is to move here lots of what's on `PBDevice`
public protocol PBBluetoothDevice: PBBasicBluetoothDevice {
    
    /// Buzzing
    /// Buzz the device.
    ///
    /// - Parameter completion: The completion block that receives a Result that is a Void on success or an PBBluetoothError on failure
    ///
    func buzz(completion: @escaping (Result<Void, PBBluetoothError>) -> Void)
    
    // Stop Buzzing
    /// Stops the buzzing of the device.
    ///
    /// - Parameter completion: The completion block that receives a Result that is a Void on success or an PBBluetoothError on failure
    ///
    func stopBuzz(completion: @escaping (Result<Void, PBBluetoothError>) -> Void)
    
    /// This function extracts, if present, the battery volts or percentage
    ///
    /// - Parameter data: The data from where the battery should be extracted. Each PBDevice should implement this methods if it's able to return battery info.
    /// - Returns: Returns a percentage if the battery info is present. When not, returns `nil`.
    func getBatteryPercentage(withManufacturerData data: Data) -> Double?
    
    /// This function sets the volume for the device
    ///
    /// - Parameter volume: The volume value to set, one of the enum `PBDeviceVolume`
    /// - Parameter completion: The completion block that receives a Result that is a Void on success or an PBBluetoothError on failure
    func setBuzzVolume(volume: PBDeviceVolume, completion: @escaping (Result<Void, PBBluetoothError>) -> Void)
    
    
    /// This function sets the device in dormant mode
    /// - Parameter completion: The completion block that receives a Result that is Void on success or a PBBluetoothError on failure.
    func setInDormantMode(completion: @escaping (Result<Void, PBBluetoothError>) -> Void)
}
