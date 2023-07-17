//
//  PBTrackingMode.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 26/01/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import UIKit

/// Tracking Mode used on the Found for stablishing how ofter it reports.
///
/// Dynamic mode is the default.
///
public enum PBTrackingMode: UInt8, CaseIterable, Comparable {
    
    case dynamic = 0
    case emergency = 1
    case lowPower = 2
    case bluetoothOnly = 3
    
    case area = 10
    case finding = 11
    case standby = 12
    case motion = 14
    case liveTracking = 15
    
    public static func getTrackingModeFrom(string: String) -> PBTrackingMode? {
        switch string {
        case "dynamic":
            return .dynamic
        case "emergency":
            return .emergency
        case "low_power":
            return .lowPower
        case "ble_only":
            return .bluetoothOnly
        case "area_tracking":
            return .area
        case "finding_mode":
            return .finding
        case "standby":
            return .standby
        case "motion_triggered":
            return .motion
        case "live_tracking":
            return .liveTracking
        default:
            return nil
        }
    }
    
    public var stringIdentifier: String {
        switch self {
        case .dynamic:
            return "dynamic"
        case .emergency:
            return "emergency"
        case .lowPower:
            return "low_power"
        case .bluetoothOnly:
            return "ble_only"
        case .area:
            return "area_tracking"
        case .finding:
            return "finding_mode"
        case .standby:
            return "standby"
        case .motion:
            return "motion_triggered"
        case .liveTracking:
            return "live_tracking"
        }
    }
    
    public var localizedDescription: String {
        switch self {
        case .dynamic:
            return NSLocalizedString("Dynamic", comment: "")
        case .emergency:
            return NSLocalizedString("Emergency", comment: "")
        case .lowPower:
            return NSLocalizedString("Low power", comment: "")
        case .bluetoothOnly:
            return NSLocalizedString("Bluetooth only", comment: "")
        case .area:
            return NSLocalizedString("Adaptive tracking", comment: "")
        case .finding:
            return NSLocalizedString("Finding mode", comment: "")
        case .standby:
            return NSLocalizedString("Standby", comment: "")
        case .motion:
            return NSLocalizedString("Motion triggered", comment: "")
        case .liveTracking:
            return NSLocalizedString("Live Tracking", comment: "")
        }
    }
    
    public static func < (lhs: PBTrackingMode, rhs: PBTrackingMode) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }
    
    private var sortOrder: Int {
        switch self {
        case .dynamic:
            return 0
        case .lowPower:
            return 1
        case .emergency:
            return 2
        case .finding:
            return 3
        case .area:
            return 4
        case .motion:
            return 5
        case .standby:
            return 6
        case .bluetoothOnly:
            return 7
        case .liveTracking:
            return 8
        }
    }
    
}
