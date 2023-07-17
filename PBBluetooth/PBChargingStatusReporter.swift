//
//  PBChargingStatusReporter.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 24/03/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import UIKit

public enum PBChargingStatus {
    case charging
    case notCharging
}

public protocol PBChargingStatusReporter {
    
    /// Retrieves the PBChargingStatus of the device
    /// - Parameter completion: The completion block that receives a Result that is a PBChargingStatus on success or an PBBluetoothError on failure
    func getChargingStatus(completion: @escaping (Result<PBChargingStatus, PBBluetoothError>) -> Void)

}
