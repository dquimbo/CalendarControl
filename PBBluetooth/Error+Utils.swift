//
//  PBBluetoothError.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 25/01/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import UIKit

public enum PBBluetoothError: Error {
    // Data error
    case valueNotAccepted
    
    // Connectivity
    case couldntDetermineDeviceState
    case couldntConnectDevice
    
    // Procedure issues
    case errorWrittingInCharacteristic
    case errorReadingValueFromCharacteristic
    case requestTimedOut

    // Other
    case featureNotAvailableInFirmware
    case bluetoothUnauthorized
}

public enum PBFirmwareUpdateError: Error {
    // Connectivity
    case couldntDetermineDeviceState
    case couldntConnectDevice
    
    // Procedure
    case errorWrittingInCharacteristic
    case errorWritingOnOverflowdedAddress
    
    // Validation
    case corruptedImage
    case failedChecksumVerification
}
