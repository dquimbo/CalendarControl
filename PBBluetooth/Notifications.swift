//
//  Notifications.swift
//  PBNetworking
//
//  Created by Jon Vogel on 12/5/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation


//MARK: Notifications for the Notification center
/// Posts when a `PBBluetoothManager` detects a signal from a `PBDevice` that was previously out of range. The `.object` property is the `PBDevice` that became reachable.
public let PBDeviceDidBecomeReachableNotification = NSNotification.Name(rawValue: "PBDeviceDidBecomeReachableNotification")
/// Posts when a `PBBluetoothManager` detect that a `PBDevice` has gone out of range. The `.object` property is the `PBDevice` that became un-reachable.
public let PBDeviceDidBecomeUnreachableNotification = NSNotification.Name(rawValue: "PBDeviceDidBecomeUnreachableNotification")
/// Posts when a battery has fallen below a critical level
public let PBBatteryStateNotification = NSNotification.Name(rawValue: "PBBatteryStateNotification")
/// Posts when the button state changes on a `PBDevice`. The `.object` property is the `PBDevice` that just got an updated `.buttonState` property. The button state is represented by the `PBButtonState` enumeration
public let PBButtonStateChangeNotification = NSNotification.Name(rawValue: "PBButtonStateChangeNotification")

//Finder Specific Notifications
/// Posts when a change in a `PBFinder`'s `.buzzState` property is detected. The `.object` property is the `PBFinder` that just got an updated `.buzzState` property.
public let PBFinderBuzzStateNotification = NSNotification.Name(rawValue: "PBFinderBuzzStateNotification")
/// Posts when a change in a `PBFinder`'s `.advertisementState` property is detected. The `.object` property is the `PBFinder` that just got an updated `.advertisementState` property.
public let PBFinderAdvertisementStateNotification = NSNotification.Name(rawValue: "PBFinderAdvertisementStateNotifiction")

public let PBDeviceAutoConnectableNotification = Notification.Name(rawValue: "PBDeviceAutoConnectableNotification")


// MARK: - TO BE REMOVED

public let PBLocationUpdateNotification = NSNotification.Name(rawValue: "PBLocationUpdated")

public let PBLocationServiceStatusNotification = NSNotification.Name(rawValue: "PBLocationServiceStatusNotification")

public let PBHeadingUpdateNotification = Notification.Name("PBHeadingUpdated")

public let PBLocationDidFailNotification = Notification.Name("PBLocationDidFail")

public let PBMonitoringDidFailNotification = Notification.Name("PBLocationMonitoringDidFail")
