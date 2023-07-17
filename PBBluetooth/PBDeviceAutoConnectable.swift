//
//  PBDeviceAutoConnectable.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 14/09/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import Foundation

/// A PBDevice that autoconnects when disconnected
public protocol PBDeviceAutoConnectable {
    
    /// Attempts to reconnect this device if in range
    func attemptToReconnect()
    
    /// Gets new RSSI value manually, the value will be returned in `didReadRSSI` method from the peripheral delegate
    func getNewRSSI()
}

/// A manager that controls which devices auto-connect
public protocol AutoConnectedDevices {
    
    /// Registers the device for auto-connecting
    /// - Parameter macAddress: MAC address of the device
    func addAutoConnectDevice(macAddress: String)
    
    /// Unregisters the device for auto-connecting
    /// - Parameter macAddress: MAC address of the device
    func removeAutoConnectDevice(macAddress: String)
    
    /// Returns a list of normalized mac addresses of all the registered devices for auto-connecting
    /// - Returns: List of MAC address
    func getAutoConnectDevices() -> [String]
    
    /// Normalizes the supplied MAC address and returns true if is already registered for auto-connecting
    /// - Parameter macAddress: MAC address of the device
    /// - Returns: Boolean indicating if the MAC is auto-connecting
    func containsAutoConnectDevice(macAddress: String) -> Bool
    
}
