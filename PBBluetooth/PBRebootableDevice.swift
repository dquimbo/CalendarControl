//
//  PBRebootableDevice.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 17/03/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import UIKit

public protocol PBRebootableDevice {
    
    /// Reboots the device
    /// - Parameter completion: The completion block that receives a Result that is a Void on success or an PBBluetoothError on failure
    func reboot(completion: @escaping (Result<Void, PBBluetoothError>) -> Void)

}
