//
//  PBCellularDevice.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 28/01/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import UIKit

public enum PBCellularDeviceLTEStatus: String {
    case connected = "connected"
    case disconnected = "disconnected"
}

/// This is the basic protocol of a Pebblebee device that connects through Cellular
public protocol PBCellularDevice {
    
    // Tracking Mode Reading
    /// Gets the tracking mode of the device as a PBTrackingMode or PBBluetoothError if failed
    ///
    /// - Parameter completion: The completion block that receives a Result that is a PBTrackingMode on success or an PBBluetoothError on failure
    ///
    func getTrackingMode(completion: @escaping (Result<PBTrackingMode, PBBluetoothError>) -> Void)
    
    // Tracking Mode Seting
    /// Sets the tracking mode of the device.
    ///
    /// - Parameter mode: The tracking mode to be set.
    /// - Parameter completion: The completion block that receives a Result that is a Void on success or an PBBluetoothError on failure
    ///
    func setTrackingMode(mode: PBTrackingMode, completion: @escaping (Result<Void, PBBluetoothError>) -> Void)
    
    // Get IMEI
    /// Returns the IMEI of the device.
    ///
    /// - Parameter completion: The completion block that receives a Result that is a String on success or an PBBluetoothError on failure
    ///
    func getIMEI(completion: @escaping (Result<String, PBBluetoothError>) -> Void)
    
    // Check if LTE is connected
    /// Returns the status of the LTE connection.
    ///
    /// - Parameter completion: The completion block that receives a Result that is a Bool on PBCellularDeviceLTEStatus or an PBBluetoothError on failure
    ///
    func getLTEStatus(completion: @escaping (Result<PBCellularDeviceLTEStatus, PBBluetoothError>) -> Void)
    
    // Get ICCID
    /// Returns the ICCID of the device.
    ///
    /// - Parameter completion: The completion block that receives a Result that is a String on success or an PBBluetoothError on failure
    ///
    func getICCID(completion: @escaping (Result<String, PBBluetoothError>) -> Void)
    
    /// Sets the debug mode on/off
    /// - Parameters:
    ///   - turnOn: Bool indicating if the debug mode should be ON.
    ///   - completion: Completion block, returns Void on success and a PBBluetoothError on failure.
    func setDebugMode(turnOn: Bool, completion: @escaping (Result<Void, PBBluetoothError>) -> Void)
    
    // Retrieves if the debug mode is on.
    /// - Parameter completion: Completion block returns Bool indicating if the debug mode is running, when success. On failure returns a PBBluetoothError.
    func getIsDebugModeOn(completion: @escaping (Result<Bool, PBBluetoothError>) -> Void)
}
