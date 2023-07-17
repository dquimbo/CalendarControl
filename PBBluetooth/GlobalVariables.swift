//
//  GlobalVariables.swift
//  PBNetworking
//
//  Created by Jon Vogel on 8/22/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import CoreBluetooth

// UUID's that represent the different iBeacon regions that we monitor for in this app.
let stoneTrackingRegionUUID = UUID(uuidString: "D149CB95-F212-4A20-8A17-E3A2F508C1FF")!
let stoneTrackingRegionIdentitifer = "Stone Tracking Region"
let finderTrackingRegionUUID = UUID(uuidString: "D149CB95-F212-4A20-8A17-E3A2F508C1AA")!
let finderTrackingRegionIdentifier = "Finder Tracking Region"
let motionRegionUUID = UUID(uuidString: "D149CB95-F212-4A20-8A17-E3A2F508C1EE")!
let motionRegionIdentifier = "Motion Region"
let inputEventRegionUUID = UUID(uuidString: "D149CB95-F212-4A20-8A17-E3A2F508C1CC")!
let inputRegionIdentitifer = "Input Region"

// Honey Services and Characteristics
// Link loss and immediate alert services work together
let linkLossServiceUUID = CBUUID(string: "1803")
let immediateAlertServiceUUID = CBUUID(string: "1802")
// They both have this characteristic
let alertLevelCharacteristicUUID = CBUUID(string: "2A06")

let linkLossCharacteristicUUID = CBUUID(string: "2A06")

let dormantCharacteristicUUID = CBUUID(string: "2B36")

//This is the battery service and characteristic
let batteryServiceUUID = CBUUID(string: "0x180F")
let batteryLevelCharacteristicUUID = CBUUID(string: "0x2A19")

//This is the temperature service and characteristic
let proprietaryTemperatureServiceUUID = CBUUID(string: "0000AB04-D105-11E1-9B23-00025B00A5A5")
let proprietaryTemperatureCharacteristicUUID = CBUUID(string: "0000AB07-D108-11E1-9B23-00025B00A5A5")

//These are other services and characteristics
let genericAccessServiceUUID = CBUUID(string: "0x1800")
let deviceNameCharacteristicUUID = CBUUID(string: "0x2A00")
let appearanceCharacteristicUUID = CBUUID(string: "0x2A01")
let peripheralPreferredConnectionParametersCharacteristicUUID = CBUUID(string: "0x2A04")
let genericAttributeServiceUUID = CBUUID(string: "0x1801")
let serviceChangedCharacteristicUUID = CBUUID(string: "0x2A05")
let transmissionPowerServiceUUID = CBUUID(string: "0x1804")
let transmissionPowerLevelCharacteristicUUID = CBUUID(string: "0x2A07")
let deviceInformationServiceUUID = CBUUID(string: "0x180A")
let manufacturerNameStringCharacteristicUUID = CBUUID(string: "0x2A29")
let serialNumberStringCharacteristicUUID = CBUUID(string: "0x2A25")
let hardwareRevisionStringCharacteristicUUID = CBUUID(string: "0x2A27")
let firmwareRevisionStringCharacteristicUUID = CBUUID(string: "0x2A26")
let softwareRevisionStringCharacteristicUUID = CBUUID(string: "0x2A28")
let plugAndPlayIdentifierCharacteristicUUID = CBUUID(string: "0x2A50")
let stopFindCharacteristicUUID = CBUUID(string: "0x2B34")
//let stopFindBuzzer2CharacteristicUUID = CBUUID(string: "0x2C01")

// Dragon specific services and characteristics
let environmentalSensingServiceUUID = CBUUID(string: "0x181A")
let temperatureCharacteristicUUID = CBUUID(string: "0x2A6E")

let proprietaryDataCharacteristicUUID = CBUUID(string: "2B01")
let proprietaryMotionEventServiceUUID = CBUUID(string: "1902")
let proprietaryMotionEventCharacteristicUUID = CBUUID(string: "2B02")


//This is the Knock's advertised service
let proprietaryDataServiceUUID = CBUUID(string: "1901")

///The global log level for the framework. See `PBLoggLevelOptions` enumeration for different values.
public var PBLogLevel: PBLoggLevelOptions = PBLoggLevelOptions.some



//Stone specific UUID's
let stoneServiceUUID = CBUUID(string: "8888")
//finder specific UUID's
let finderServiceUUID = CBUUID(string: "FA25")
//found specific UUID's
let foundServiceUUID = CBUUID(string: "FA26")
//Location Marker service UUID
let locationBeaconServiceUUID = CBUUID(string: "FB25")
//finder specific UUID's
let smpServiceUUID = CBUUID(string: "8D53DC1D-1DB7-4CD3-868B-8A527460AA84")
//R4K Tag Service
let r4kTagServiceUUID = CBUUID(string: "FCC7")

//let cellularServiceUUID = CBUUID(string: "53616D70-6C65-4170-7044-656D6F010000")

//Write to
let data1CharacteristicUUID = CBUUID(string: "2C01")
let data2CharacteristicUUID = CBUUID(string: "2C02")
let data3CharacteristicUUID = CBUUID(string: "2C06")
let debugModeCharacteristicUUID = CBUUID(string: "3C01")

//Write to
let buzzer2WriteToDisconnectCharacteristicUUID = CBUUID(string: "2C02")
let buzzer2WriteToBuzzCharacteristicUUID = CBUUID(string: "2C01")
//Advertisement packet prefixes for different devices


//iBeacon broadcast UUID
internal let beaconUUID = UUID(uuidString: "BEEFBEEF-CAFE-CAFE-DEAD-DEADBEEFCAFE")!
internal let beaconSignalName = "TestBeaconSignal"
