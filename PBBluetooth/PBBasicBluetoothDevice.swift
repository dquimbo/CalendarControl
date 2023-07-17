//
//  PBBasicBluetoothDevice.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 01/02/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import UIKit

public protocol PBBasicBluetoothDevice {
    
    /// Buzzing
    /// Buzz the device.
    ///
    /// - Parameter completion: The completion block that receives a Result that is a Void on success or an PBBluetoothError on failure
    ///
    func buzz(completion: @escaping (Result<Void, PBBluetoothError>) -> Void)

}
