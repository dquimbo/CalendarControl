//
//  PBHoney.swift
//  PBNetworking
//
//  Created by Jon Vogel on 11/29/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 The two different ways that you can find a 'PBHoney'
 
 - lightUp: The 'PBHoney' will flash the built in LED
 - buzz: The 'PBHoney' will make a noise
 */
public enum PBHoneyFindOptions {
    ///- lightUp: The 'PBHoney' will flash the built in LED
    case lightUp
    ///- buzz: The 'PBHoney' will make a noise
    case buzz
    ///- lingBuzz: The `PBHoney` will buzz 4 times in a row
    case longBuzz
}

/**
 Error's that can happen when you try and 'find' a 'PBHoney'
 
 - connectionFail(error: Error): We were not able to connect to the Honey for the reason passed through in this case.
 - notConnected: The 'PBHoney' was not connected.
 - findOptionNotDefined: No option for the 'PBHoneyFindOptions' was detected.
 */
public enum PBHoneyFindError {
    ///- connectionFail(error: Error): We were not able to connect to the Honey for the reason passed through in this case.
    case connectionFail(error: Error)
    ///- notConnected: The 'PBHoney' was not connected.
    case notConnected
    ///- findOptionNotDefined: No option for the 'PBHoneyFindOptions' was detected.
    case findOptionNotDefined
}

/**
 The firmware verison of the 'PBHoney'
 
 - unknown: We have not been able to determine the verison of the firmware
 - preRobert: The old firmware
 - robertRevision: The new firmware
 */
public enum PBHoneyFirmwareVersion: Int {
    ///- unknown: We have not been able to determine the verison of the firmware
    case unknown = 0
    ///- preRobert: The old firmware
    case preRobert = 1
    ///- robertRevision: The new firmware
    case robertRevision = 5
}

/// This class represents our Honey Product and all the interactions available.
public class PBHoney: PBDevice {
    
    
    // The characteristic that will let us light up and buzz the Honey
    @objc var alertLevelCharacteristic: CBCharacteristic? {
        didSet{
            // If we just set the Characteristic see if we were trying to buzz it.
            self.writeToBuzz()
        }
    }
    
    @objc var batteryCharacteristic: CBCharacteristic? {
        didSet{
            
        }
    }
    
    
    @objc var temperatureCharacteristic: CBCharacteristic? {
        didSet{
            
        }
        
    }
    
    @objc var linklossCharacteristic: CBCharacteristic? {
        didSet{
            
        }
        
    }
    
    
    @objc var needToBuzz = false
    
    var buzzType: PBHoneyFindOptions?
    
    var findCompletion: ((_ findError: PBHoneyFindError?) -> Void)?
    
    var batteryComplete: ((_ batteryPercentage: Int?) -> Void)?
    
    
    /// This variable determines how the framework handles `find` requests for a given `PBHoney`. It is useful from a public perspective for dispalying different UI elements for the different `PBHoney` version as they have different plastics
    public var firmwareVersion: PBHoneyFirmwareVersion = .unknown {
        didSet{
            //let dic = [PBDebugTitleKey: "Set Firmware version", PBDebugMessageKey: "Set firmware model number to \(self.getFirmwareVerionString()) for device with macAddress: \(self.macAddress)"]
            //NotificationCenter.default.post(name: PBDebugNotificaiton, object: dic)
        }
    }
    
    override init(withMacAddress address: String) {
        super.init(withMacAddress: address)
        
        self.deviceType = .honey
        self.dataParser = PBHoneyAdvertisementParser()
    }
    
    /// Call this function after a successful connection to discover the services.
    override public func discoverServices() {
        self.peripheral?.discoverServices([immediateAlertServiceUUID, linkLossServiceUUID, batteryServiceUUID, proprietaryTemperatureServiceUUID])
    }
    
    /// Request the battery from the PBHoney. Will return the value in the completion and populate the `.batteryValue` property.
    ///
    /// - Parameter completion: Completion that contains the read battery value as a percentage. Will return `nil` if the `PBHoney` is not in the connected state or if there was an error readign the value.
    public func requestBattery(completion: @escaping (_ batteryPercentage: Int?) -> Void) {
        guard self.batteryComplete == nil else {
            return
        }
        
        
        self.batteryComplete = completion
        
        guard let c = self.batteryCharacteristic else {
            self.batteryComplete?(nil)
            self.batteryComplete = nil
            return
        }
        
        self.peripheral?.readValue(for: c)
        
    }
    
    /**
     This function lets you interact with the Honey's 'finding' capabilities
     
     - Parameters:
     - option: The 'PBHoneyFindOptions' that will determine what hardware to activate to find the 'PBHoney'
     - withManager: You can pass the find request a 'PBBluetoothManager' and it will attempt to resolve any connection problems and then buzz the device. So if you use this paramater you do not have to have an established connection to find the Honey. If you don't pass this value and the Honey is not connected you will get an error.
     - completion: The completion with a possible error describing what went wrong. If the error is nil then the 'find' was successful.
     */
    public func find(_ option: PBHoneyFindOptions, withManager m: PBBluetoothManager?, completion: @escaping (_ findError: PBHoneyFindError?) -> Void) {
        // Make sure we can get the state of the peripheral
        guard let state = self.connectionState else {
            // If not send a connection error
            completion(PBHoneyFindError.notConnected)
            return
        }
        
        // Set the find completion to the functions conpletion
        self.findCompletion = completion
        // Set needs buzz to true
        self.needToBuzz = true
        // Set the Buzz option
        self.buzzType = option
        
        //Swith on the State
        switch state {
        case .connected:
            //If we are connected then try and write to the characteristic to buzz
            self.writeToBuzz()
        case .disconnected:
            //If we are disconnected see if they gave us a manager to connect to
            guard let manager = m else {
                // If they did not return a not connected error
                self.findCompletion?(PBHoneyFindError.notConnected)
                return
            }
            
            //If they did, try and connect
            manager.connectDevice(device: self, completion: { (error) in
                if let e = error {
                    //If we got an error then pass the error through
                    self.findCompletion?(PBHoneyFindError.connectionFail(error: e))
                }else{
                    //If not error then discover services
                    self.discoverServices()
                }
            })
            
        case .connecting, .disconnecting:
            //If Connected or connecting State return a not connected error
            self.findCompletion?(PBHoneyFindError.notConnected)
        @unknown default:
            break
        }
    }
    
    
    // Handles writing the the appropriate characteristics to Buzz the Honey
    @objc func writeToBuzz() {
        
        // First see if we need to Buzz
        guard self.needToBuzz else{
            //If not return
            return
        }
        
        //See if we have the appropriate characteristic
        guard let c = self.alertLevelCharacteristic else {
            self.findCompletion?(PBHoneyFindError.notConnected)
            return
        }
        
        // See if we know how the device is supposed to be Buzzed
        guard let option = self.buzzType else {
            self.findCompletion?(PBHoneyFindError.findOptionNotDefined)
            return
        }
        

        //Switch on the option
        switch option {
        case .buzz:
            //If it is Buzz then write 02
            let beepValue = Data(bytes: UnsafePointer<UInt8>([UInt8(0x02)]), count: MemoryLayout<UInt8>.size)
            switch self.firmwareVersion {
            case .unknown, .preRobert:
                //Write 00 to reset the Honey
                let reSet = Data(bytes: UnsafePointer<UInt8>([UInt8(0x00)]), count: MemoryLayout<UInt8>.size)
                self.peripheral?.writeValue(reSet, for: c, type: CBCharacteristicWriteType.withoutResponse)
                self.peripheral?.writeValue(beepValue, for: c, type: CBCharacteristicWriteType.withoutResponse)
            case .robertRevision:
                self.peripheral?.writeValue(beepValue, for: c, type: CBCharacteristicWriteType.withResponse)
            }
            
        case .lightUp:
            //If it is light up then write 01
            let lightValue = Data(bytes: UnsafePointer<UInt8>([UInt8(0x01)]), count: MemoryLayout<UInt8>.size)
            
            switch self.firmwareVersion {
            case .unknown, .preRobert:
                //Write 00 to reset the Honey
                let reSet = Data(bytes: UnsafePointer<UInt8>([UInt8(0x00)]), count: MemoryLayout<UInt8>.size)
                self.peripheral?.writeValue(reSet, for: c, type: CBCharacteristicWriteType.withoutResponse)
                self.peripheral?.writeValue(lightValue, for: c, type: CBCharacteristicWriteType.withoutResponse)
            case .robertRevision:
                self.peripheral?.writeValue(lightValue, for: c, type: CBCharacteristicWriteType.withResponse)
            }
        case .longBuzz:
            let longBuzzValue = Data(bytes: UnsafePointer<UInt8>([UInt8(0x03)]), count: MemoryLayout<UInt8>.size)
            switch self.firmwareVersion {
            case .unknown, .preRobert:
                //Write 00 to reset the Honey
                let reSet = Data(bytes: UnsafePointer<UInt8>([UInt8(0x00)]), count: MemoryLayout<UInt8>.size)
                self.peripheral?.writeValue(reSet, for: c, type: CBCharacteristicWriteType.withoutResponse)
                self.peripheral?.writeValue(longBuzzValue, for: c, type: CBCharacteristicWriteType.withoutResponse)
            case .robertRevision:
                self.peripheral?.writeValue(longBuzzValue, for: c, type: CBCharacteristicWriteType.withResponse)
            }
        }
        
        
        switch self.firmwareVersion {
        case .unknown, .preRobert:
            //Fulfill any pendign completion with no error
            DispatchQueue.main.async {
                self.findCompletion?(nil)
                //Set needs to Buzz to false
                self.needToBuzz = false
                //Set Buzz Type to nil
                self.buzzType = nil
            }
        case .robertRevision:
            return
        }

    }
    
}


// Extension that handels the peripheral service and characteristic discoveries
extension PBHoney {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else {
            return
        }
        
        
        
        for s in services {
            
            switch s.uuid{
            case immediateAlertServiceUUID:
                //Look for ALert Level Characteristic
                peripheral.discoverCharacteristics([alertLevelCharacteristicUUID], for: s)
            case linkLossServiceUUID:
                peripheral.discoverCharacteristics([linkLossCharacteristicUUID], for: s)
            case batteryServiceUUID:
                peripheral.discoverCharacteristics([batteryLevelCharacteristicUUID], for: s)
            case proprietaryTemperatureServiceUUID:
                peripheral.discoverCharacteristics([proprietaryTemperatureCharacteristicUUID], for: s)
            default:
                return
            }
            
            
            
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for c in characteristics {
            
            switch c.uuid {
            case alertLevelCharacteristicUUID:
                if service.uuid == immediateAlertServiceUUID {
                    self.alertLevelCharacteristic = c
                }
                else if service.uuid == linkLossServiceUUID {
                    self.linklossCharacteristic = c
                    peripheral.setNotifyValue(true, for: self.linklossCharacteristic!)
                }
            case batteryLevelCharacteristicUUID:
                self.batteryCharacteristic = c
                peripheral.setNotifyValue(true, for: self.batteryCharacteristic!)
            case proprietaryTemperatureCharacteristicUUID:
                self.temperatureCharacteristic = c
            case   linkLossCharacteristicUUID:
                self.linklossCharacteristic = c
                peripheral.setNotifyValue(true, for: self.linklossCharacteristic!)
                return
            default:
                return
            }
        }
        
    }
    
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == self.alertLevelCharacteristic?.uuid {
            switch self.firmwareVersion {
            case .unknown, .preRobert:
                return
            case .robertRevision:
                //Fulfill any pendign completion with no error
                DispatchQueue.main.async {
                    self.findCompletion?(nil)
                    //Set needs to Buzz to false
                    self.needToBuzz = false
                    //Set Buzz Type to nil
                    self.buzzType = nil
                }
            }
        }
    }
    
    
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case batteryLevelCharacteristicUUID:
            guard let data = characteristic.value else {
                return
            }
            
            var volt: UInt8 = 0
            
            data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) in
                volt = UInt8(bytes.pointee)
            })
            
            self.batteryPercentage = Double(volt)
            
            DispatchQueue.main.async {
                self.batteryComplete?(Int(volt))
                self.batteryComplete = nil
            }
            
        case linkLossCharacteristicUUID:
            guard let _ = characteristic.value else {
                return
            }
            
            guard let data = characteristic.value else {
                return
            }
            if(data.count == 1){
                var command: UInt8 = 0
                
                data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) in
                    command = UInt8(bytes.pointee)
                })
                if (command == 171){
                        self.buttonState = .singlePress
                    return
                }
                
            }
            
        case proprietaryTemperatureCharacteristicUUID:
            guard let _ = characteristic.value else {
                return
            }
           // self.temperatureAttribute?.update(fromData: data)
        default:
            return
        }
        
    }
    
    
    @objc internal func getFirmwareVerionString() -> String {
        switch self.firmwareVersion {
        case .unknown:
            return "UNKNOWN"
        case .preRobert:
            return "PRE ROBERT TREATMENT"
        case .robertRevision:
            return "POST ROBERT TREATMENT"
        }
    }
    
}

// MARK: - PBBasicBluetoothDevice

extension PBHoney: PBBasicBluetoothDevice {
    
    public func buzz(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        find(.buzz, withManager: PBBluetoothManager.shared) { (error) in
            if let _ = error {
                completion(.failure(.couldntConnectDevice))
            } else {
                completion(.success(()))
            }
        }
    }
    
}


