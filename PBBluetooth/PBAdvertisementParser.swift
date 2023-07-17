//
//  PBDataParser.swift
//  PBNetworking
//
//  Created by Jon Vogel on 12/2/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation

//Base Class for handling data packet parsing per device
internal class PBAdvertisementParser {
    
    /// Updates the PBDevice with the information gotten from the advertisement
    /// - Parameters:
    ///   - data: The advertisement data
    ///   - device: The device to be updated
    func update(withAdvertisement data: [String : Any], manufacturerData: Data, device: PBDevice) {
        if let newPercentage = (device as? PBBluetoothDevice)?.getBatteryPercentage(withManufacturerData: manufacturerData) {
            device.batteryPercentage = newPercentage
        }
        
        device.lastSeenTime = Date()
        device.mark(inRange: true, notify: true)
    }
    
}
