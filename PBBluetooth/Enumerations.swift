//
//  Enumerations.swift
//  PBNetworking
//
//  Created by Jon Vogel on 11/18/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation


/**
The log levels that are allowes in the PBBluetooth Framework. All logg are deliverer through the `PBDebugNotificaiton`
*/
public enum PBLoggLevelOptions: Int {
    ///Nothing will get returned for logging
    case none = 0
    ///Some basic information will get logged when the framework starts up. Then, infrequent events after that
    case some = 1
    ///Log everything the framework is capable of logging.
    case verbose = 2
}
/**
 Represents a 'PBDeviceManger''s access to system location services.
 
    - Unavailable: Location services are unavailable.
    - Unauthorized: Location services have not been granted sufficient authorization.
    - Authorized: Location services are authorized and available.
 
 */
public enum PBLocationServicesStatus {
    ///- Unavailable: Location services are unavailable.
    case Unavailable
    ///- Unauthorized: Location services have not been granted sufficient authorization.
    case Unauthorized
    ///- Authorized: Location services are authorized and available.
    case Authorized
}

/**
Represents a 'PBDeviceManger''s access to system Bluetooth services.
 
    - Unavailable: Bluetooth is unavailable.
    - Unauthorized: Bluetooth has not been granted sufficient authorization.
    - Authorized: Bluetooth is authorized and available.
 
 */
public enum PBBluetoothCentralStatus {
    ///- Unavailable: Bluetooth is unavailable.
    case Unavailable
    ///- Unauthorized: Bluetooth has not been granted sufficient authorization.
    case Unauthorized
    ///- Authorized: Bluetooth is authorized and available.
    case Authorized
    ///- Other, like resseting, unsupported, or unknown
    case Other
}

/**
 Represents a 'PBDeviceManger''s ability to broadcast bluetooth data
 
    - Unavailable: Bluetooth advertising is unavailable (system error)
    - Unauthorized: Bluetooth advertising has not been authorized
    - Authorized: Bluetooth advertising hse been set up correctly and is available
 
 */
public enum PBBluetoothAdvertisingStatus {
    ///- Unavailable: Bluetooth advertising is unavailable (system error)
    case Unavailable
    ///- Unauthorized: Bluetooth advertising has not been authorized
    case Unauthorized
    ///- Authorized: Bluetooth advertising hse been set up correctly and is available
    case Authorized
}

/**
The current state of a 'PBStone''s button
 
 - pressed: The button has just been pressed
 - held: The button has just been held for three seconds
 - staticSignal: The button press is in its normal state (no interaction)
 - resetting: The button is resetting. (Moving from pressed/held to static signal)
 - unknown: We could not read the button state
 - neverPressed: The button has never been interacted with (New Stone)
 */
public enum PBButtonState {
    ///- none: The button press is in its normal state (no interaction)
    case none
    ///- pressed: The button has just been pressed
    case singlePress
    ///- longPress: The button has just been held for three seconds
    case longPress
    ///- doubleTapped: The button has been double tapped
    case doublePress
    ///- triplePress: Only avaible for MFi Devices
    case triplePress
    ///- quadruplePress: Only avaible for MFi Devices
    case quadruplePress
    ///- quintuplePress: Only avaible for MFi Devices
    case quintuplePress
    ///- doublePressAndHold: Only avaible for MFi Devices
    case doublePressPlusHold
    ///- triplePressAndHold: Only avaible for MFi Devices
    case triplePressPlusHold
    
    var stringValue: String {
        switch self {
        case .longPress:
            return "Long Press"
        case .singlePress:
            return "Single Press"
        case .doublePress:
            return "Double Press"
        case .triplePress:
            return "Triple Press"
        case .quadruplePress:
            return "Quadruple Press"
        case .quintuplePress:
            return "Quintuple Press"
        case .doublePressPlusHold:
            return "Double Press Plus Hold"
        case .triplePressPlusHold:
            return "Triple Press Plus Hold"
        case .none:
            return "None"
        }
    }

}


/// The different buzz states for the devices
public enum PBBuzzState {
    case iddle
    case attemptingBuzz
    case buzzing
    case attemptingStop
}


/**
 The adversitement state of the a 'PBFinder'
 - high: The 'PBFinder' is rapidly broadcasting bluetooth packets
 - low: The 'PBFinder' is broadcasting bluetooth packets very infrequently. Call 'wakeUp' on the finder to change it to high broadcast
 - unknown: The advertisement state of the 'PBFinder' is unknown
 */
public enum PBFinderAdvertisementState: Int {
    ///- high: The 'PBFinder' is rapidly broadcasting bluetooth packets
    case high = 1
    ///- low: The 'PBFinder' is broadcasting bluetooth packets very infrequently. Call 'wakeUp' on the finder to change it to high broadcast
    case low = 2
    ///- unknown: The advertisement state of the 'PBFinder' is unknown
    case unknown = 3
    
    public var localizedDescription: String {
        switch self {
        case .high:
            return NSLocalizedString("high", comment: "high")
        case .low:
            return NSLocalizedString("low", comment: "low")
        case .unknown:
            return NSLocalizedString("unknown", comment: "unknown")
        }
    }
}

///The advertisement state of a `PBBuzzer2`
public enum PBBuzzer2AdvertisementState: Int {
    ///Broadcasting bluetooth packets rapidly
    case high = 1
    ///Rarely broadcasting bluetooth packets
    case low = 2
    ///The state is unknown
    case unknown = 3
}


///The buzzing state of the `PBBuzzer2`
public enum PBBuzzer2BuzzState: Int {
    ///The LED on the `PBBuzzer2` in illuminating
    case illuminated = 1
    ///Both the LED on the `PBBuzzer2` is illuminating and the `PBBuzzer2` is making a sound
    case buzzing = 2
    ///The `PBBuzzer` is not doing anything
    case notBuzzing = 3
    ///The state is unknown
    case unknown = 4
}


/**
 The motion state of the a 'PBStone'
 - notMoving: The 'PBStone' is not moving
 - moving: The 'PBStone' moving
 - unknown: The 'PBStoneMotionState' for the 'PBStone' is unknown
 */
public enum PBStoneMotionState {
    ///- notMoving: The 'PBStone' is not moving
    case notMoving
    ///- moving: The 'PBStone' moving
    case moving
    ///- unknown: The 'PBStoneMotionState' for the 'PBStone' is unknown
    case unknown
}

/**
 Represents an error that can occure when a peripheral connection request fails
 - noDiscoveredPeripheral: Core bluetooth has not detected a matching peripheral for this 'PBDevice'
 - operatingSystemError(e: Error?): A core bluetooth error was returned form iOS.
 */
public enum PBPeripheralConnectionError: Error {
    ///- noDiscoveredPeripheral: Core bluetooth has not detected a matching peripheral for this 'PBDevice'
    case noDiscoveredPeripheral
    ///- operatingSystemError(e: Error?): A core bluetooth error was returned form iOS.
    case operatingSystemError(e: Error?)
}


/**
 Represents an error that can occure when a peripheral dis-connection request fails
 - noDiscoveredPeripheral: Core bluetooth has not detected a matching peripheral for this 'PBDevice'
 - peripheralNotConnected: The underlying peripheral is not in a connected state
 - operatingSystemError(e: Error?): A core bluetooth error was returned form iOS.
 */
public enum PBPeripheralDisconnectionError: Error {
    ///- noDiscoveredPeripheral: Core bluetooth has not detected a matching peripheral for this 'PBDevice'
    case noDiscoveredPeripheral
    ///- peripheralNotConnected: The underlying peripheral is not in a connected state
    case peripheralNotConnected
    ///- operatingSystemError(e: Error?): A core bluetooth error was returned form iOS.
    case operatingSystemError(e: Error?)
}


/**
    Represents the keys in a `LocationHistory` `.JSONPiece` object.
 */
public enum PBLocationHistoryKey: String{
    /// The time stamp from 1970 in millisecodns
    case timestampKey = "location_time"
    /// The latitude
    case latitudeKey = "latitude"
    ///The longitude
    case longitudeKey = "longitude"
    
    case batteryKey = "battery_mv"
}


enum Product: UInt16 {
    case honeyProductID = 0x0E0A
    case finderProductID = 0x0E0E
    case cardProductID = 0x0E05
    case finder2ProductID = 0x0E06
    case foundProductID = 0x0E07
    
    var deviceType: PBDeviceType {
        switch self {
        case .honeyProductID:
            return .honey
        case .finderProductID:
            return .finder
        case .cardProductID:
            return .card
        case .finder2ProductID:
            return .finder2
        case .foundProductID:
            return .found
        }
    }
}

/// Battery capacity devices, millivolt unit
public struct BatteryCapacityLevel {
    // For Finder, Finder 2.0, Found
    static let finderMin = 2000
    static let finderMax = 3200
    
    static let honey1Min = 2000
    static let honey1Max = 3200
    
    static let cardMin = 2750
    static let cardMax = 4200
}
