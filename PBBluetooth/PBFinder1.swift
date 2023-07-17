//
//  PBFinder.swift
//  PBNetworking
//
//  Created by Jon Vogel on 11/29/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 The two different ways that you can find a 'PBFinder'
 
 - longRange: This is our secret sauce and adds a little extra range on the Buzzing. Requires that the app has been authorized to broadcast bluetooth
 - shortRange: Good old fashion write to a characteristic way of finding a 'PBFinder'
 */
public enum PBFinderFindOptions {
    ///- longRange: This is our secret sauce and adds a little extra range on the Buzzing. Requires that the app has been authorized to broadcast bluetooth
    case longRange
    ///- shortRange: Good old fashion write to a characteristic way of finding a 'PBFinder'
    case shortRange
}

//let byteArrayDormant = [UInt8(0x04), UInt8(0x00), UInt8(0x00), UInt8(0x00), UInt8(0x00), UInt8(0x00), UInt8(0x01)]

/**
 Error's that can happen when you try and 'find' a 'PBFinder'
 
 - connectionFail(error: Error): This means that something went wrong with the bluetooth connection. You get passed back another error from the 'PBBluetoothManager'
 - bluetoothError(error: Error): This means that something went wrong with the bluetooth connection. You get passed back another error from the iOS operating system
 - broadcastFail(fellback: Bool) This means that something went wrong when we tried to turn the app into a Bluetooth peripheral. You get passed back an operating system error.
 */
public enum PBFinderFindError {
    ///- This gets thrown if you are not connected and you tried to buzz with the `shortRange` option and you did not provide a `PBBluetoothManager`
    case notConnected
    ///- connectionFail(error: Error): This means that something went wrong with the bluetooth connection. You get passed back another error from the 'PBBluetoothManager'
    case connectionFail(error: Error)
    ///- bluetoothError(error: Error): This means that something went wrong with the bluetooth connection. You get passed back another error from the iOS operating system
    case bluetoothError(error: Error)
    ///- broadcastFail(fellback: Bool) This means that something went wrong when we tried to turn the app into a Bluetooth peripheral. You get passed back an operating system error.
    case broadcastFail(fellback: Bool)
    ///- This error gets thrown if you try to buzz with the `longRange` option and the peripheral is currently connected
    case connected
}


///Errors that could happen when you try and set the `PBFinder` to dormant
public enum PBSetDormantError {
    ///Could not establish a connection to the peripheral
    case connectionFail(error: Error)
    ///CoreBluetooth returned and error and could not interact with the device
    case bluetoothError(error: Error)
    ///The device is not connected.
    case notConnected
}

public enum PBSetOTAError {
    ///Could not establish a connection to the peripheral
    case connectionFail(error: Error)
    ///CoreBluetooth returned and error and could not interact with the device
    case bluetoothError(error: Error)
    ///The device is not connected.
    case notConnected
}

public enum PBSetGenericError {
    ///Could not establish a connection to the peripheral
    case connectionFail(error: Error)
    ///CoreBluetooth returned and error and could not interact with the device
    case bluetoothError(error: Error)
    ///The device is not connected.
    case notConnected
}

/// Class that represents Pebblebee's Finder product.
public class PBFinder1: PBDevice {

    ///The major value that will be broadcast for iBeacon stuff
    public internal(set) var major: Int!
    ///The minor value that will be broadcast for iBeacon stuff
    public internal(set) var minor: Int!
    
    @objc var needToBuzz = false
    
    @objc var setDormant = false
    
    @objc var setOTA = false
    
    @objc var setCancelBuzz = false
    
    @objc var setReboot = false
    
    @objc var setJingle = false
    @objc var setJingleValue = 2

    @objc var setVolume = false
    @objc var setVolumeValue = 3
    
    @objc var resetDevice = false

    
    var setDormantCompletion: ((_ error: PBSetDormantError?) -> Void)?
    var setOTACompletion: ((_ error: PBSetOTAError?) -> Void)?
    var setCancelBuzzCompletion: ((_ error: PBSetGenericError?) -> Void)?
    var setRebootCompletion: ((_ error: PBSetGenericError?) -> Void)?
    var setJingleCompletion: ((_ error: PBSetGenericError?) -> Void)?
    var setVolumeCompletion: ((_ error: PBSetGenericError?) -> Void)?
    var resetDeviceCompletion: ((_ error: PBSetGenericError?) -> Void)?
    
    // MARK: - Firmwware Version
    
    private var gettingFirmwareVersion = false
    private var getFirmwareVersionCompletion: ((Result<String, PBBluetoothError>) -> Void)?
    
    @objc var needToWakeUp = false
    
    var buzzType: PBFinderFindOptions?
    
    var findCompletion: ((_ findError: PBFinderFindError?) -> Void)?
        
    @objc internal var data2Characteristic: CBCharacteristic? {
        didSet{
            if self.buzzType == PBFinderFindOptions.longRange && self.needToBuzz {
                self.writeForDisconnect()
            }else if self.needToWakeUp{
                self.writeForDisconnect()
            }
            
        }
    }
    
    @objc internal var data1Characteristic: CBCharacteristic? {
        didSet{
            if self.buzzType == PBFinderFindOptions.shortRange {
                self.writeForBuzz()
            }
            else if self.setDormant {
                self.writeForDormant()
            }
            else if self.setOTA {
                self.writeForOTA()
            }
            else if self.setJingle {
                self.writeForJingleChange(JingleIndex: setJingleValue)
            }
            else if self.setVolume {
                self.writeForVolumeChange(VolumeIndex: setVolumeValue)
            }
            else if self.setReboot {
                self.writeForReboot()
            }
            else if self.setCancelBuzz {
                self.writeForCancelBuzz()
            }
            else if self.resetDevice {
                self.writeToReset()
            }
            else {
                print("--- data1Characteristic none to do")
            }
        }
    }
    
    
    /// The current buzz state of the `PBFinder`. Changes for this value for any `PBFinder` are broadcast through the `PBFinderBuzzStateNotification`
    public internal(set) var buzzState: PBBuzzState = PBBuzzState.iddle {
        didSet{
            if self.buzzState == PBBuzzState.buzzing && self.needToBuzz == true {
                DispatchQueue.main.async {
                    self.findCompletion?(nil)
                    self.findCompletion = nil
                    self.buzzType = nil
                    self.needToBuzz = false
                    self.needToWakeUp = false
                    PBBroadcastManager.shared.stopLocalBeacon(self)
                }
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: PBFinderBuzzStateNotification, object: self)
            }
            
        }
    }
    
    
    /// The current advertisement state of the `PBFinder`. Changes for this value for any `PBFider` are broadcast through the `PBFinderAdvertisementStateNotification`.
    public internal(set) var advertisementState: PBFinderAdvertisementState = PBFinderAdvertisementState.unknown {
        didSet{
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: PBFinderAdvertisementStateNotification, object: self)
            }
        }
    }

    required init(withAMacAddress mac: String, andMajor maj: Int, andMinor min: Int) {
        super.init(withMacAddress: mac)
        self.major = maj
        self.minor = min
        self.dataParser = PBFinderAdvertisementParser()
        self.deviceType = .finder
    }
    
    /// Starts the discovery sequence for characteristics and services. This will not do anything if the device is not connected. Call this when a connection request for a device has returned with out an error.
    override public func discoverServices() {
        print("\(#function): \(finderServiceUUID)")
        print("\(#function): \(String(describing: peripheral))")
        self.peripheral?.discoverServices([finderServiceUUID])
    }
    
    
    
    //MARK: - Public functions
    
    /// `PBFinder`'s change to a slow broadcast mode after 5 minutes. Calling this function will attempt to `wakeup` the finder. The State of the advertisement is broadcast by the `PBFinderAdvertisementStateNotification` and represented by the `advertisementState` property.
    ///
    /// - Parameter m: A `PBBluetoothManager` that will be used to wake up the `PBFinder`
    @objc public func wakeUpFinder(withManager m: PBBluetoothManager) {
        
        m.connectDevice(device: self) { (error) in
            if let e = error {
                print(e)
            }else{
                self.needToWakeUp = true
                self.discoverServices()
                
            }
        }
    }
    
    
    
    /// This function will set the `PBFinder` to dormant mode.
    ///
    /// - Parameters:
    ///   - m: The `PBBluetoothManager` that will assist in setting to dormant mode
    ///   - completion: The completion handle that will pass back a `PBSetDormantError` if the request failed.
    public func setDormant(withManager m: PBBluetoothManager?, completion: @escaping (_ error: PBSetDormantError?) -> Void) {
        
        self.setDormantCompletion = completion
        self.setDormant = true
        
        guard let state = self.connectionState else {
            self.setDormantCompletion?(PBSetDormantError.notConnected)
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.setDormantCompletion?(PBSetDormantError.notConnected)
        case .connected:
            self.writeForDormant()
        case .disconnected:
            guard let manager = m else {
                self.setDormantCompletion?(PBSetDormantError.notConnected)
                return
            }
            
            manager.connectDevice(device: self, completion: { (error) in
                if let e = error {
                    self.setDormantCompletion?(PBSetDormantError.connectionFail(error: e))
                }else{
                    self.discoverServices()
                }
            })
        @unknown default:
            break
        }
        
    }
    
    public func setOTA(withManager m: PBBluetoothManager?, completion: @escaping (_ error: PBSetOTAError?) -> Void) {
        
        self.setOTACompletion = completion
        self.setOTA = true
        
        guard let state = self.connectionState else {
            self.setOTACompletion?(PBSetOTAError.notConnected)
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.setOTACompletion?(PBSetOTAError.notConnected)
        case .connected:
            self.writeForOTA()
        case .disconnected:
            guard let manager = m else {
                self.setOTACompletion?(PBSetOTAError.notConnected)
                return
            }
            
            manager.connectDevice(device: self, completion: { (error) in
                if let e = error {
                    self.setOTACompletion?(PBSetOTAError.connectionFail(error: e))
                }else{
                    self.discoverServices()
                }
            })
        @unknown default:
            break
        }
        
    }
    
    //finder 2 really
    public func setCancelBuzz(withManager m: PBBluetoothManager?, completion: @escaping (_ error: PBSetGenericError?) -> Void) {
        
        self.setCancelBuzzCompletion = completion
        self.setCancelBuzz = true
        
        guard let state = self.connectionState else {
            self.setCancelBuzzCompletion?(PBSetGenericError.notConnected)
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.setCancelBuzzCompletion?(PBSetGenericError.notConnected)
        case .connected:
            self.writeForCancelBuzz()
        case .disconnected:
            guard let manager = m else {
                self.setCancelBuzzCompletion?(PBSetGenericError.notConnected)
                return
            }
            
            manager.connectDevice(device: self, completion: { (error) in
                if let e = error {
                    self.setCancelBuzzCompletion?(PBSetGenericError.connectionFail(error: e))
                }else{
                    self.discoverServices()
                }
            })
        @unknown default:
            break
        }
        
    }
    
    public func setReboot(withManager m: PBBluetoothManager?, completion: @escaping (_ error: PBSetGenericError?) -> Void) {
        
        self.setRebootCompletion = completion
        self.setReboot = true
        
        guard let state = self.connectionState else {
            self.setRebootCompletion?(PBSetGenericError.notConnected)
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.setRebootCompletion?(PBSetGenericError.notConnected)
        case .connected:
            self.writeForReboot()
        case .disconnected:
            guard let manager = m else {
                self.setRebootCompletion?(PBSetGenericError.notConnected)
                return
            }
            
            manager.connectDevice(device: self, completion: { (error) in
                if let e = error {
                    self.setRebootCompletion?(PBSetGenericError.connectionFail(error: e))
                }else{
                    self.discoverServices()
                }
            })
        @unknown default:
            break
        }
        
    }
    
    public func setJingle(withManager m: PBBluetoothManager?, indexValue val: Int?,  completion: @escaping (_ error: PBSetGenericError?) -> Void) {
        
        self.setJingleCompletion = completion
        self.setJingle = true
        self.setJingleValue = val ?? 2
        
        guard let state = self.connectionState else {
            self.setJingleCompletion?(PBSetGenericError.notConnected)
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.setJingleCompletion?(PBSetGenericError.notConnected)
        case .connected:
            self.writeForJingleChange(JingleIndex: val ?? 3)
        case .disconnected:
            guard let manager = m else {
                self.setJingleCompletion?(PBSetGenericError.notConnected)
                return
            }
            
            manager.connectDevice(device: self, completion: { (error) in
                if let e = error {
                    self.setJingleCompletion?(PBSetGenericError.connectionFail(error: e))
                }else{
                    self.discoverServices()
                }
            })
        @unknown default:
            break
        }
        
    }
    
    public func setVolume(withManager m: PBBluetoothManager?, indexValue val: Int?, completion: @escaping (_ error: PBSetGenericError?) -> Void) {
        
        self.setVolumeCompletion = completion
        self.setVolume = true
        self.setVolumeValue = val ?? 3
        
        guard let state = self.connectionState else {
            self.setVolumeCompletion?(PBSetGenericError.notConnected)
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            self.setVolumeCompletion?(PBSetGenericError.notConnected)
        case .connected:
            self.writeForVolumeChange(VolumeIndex: val ?? 3)
        case .disconnected:
            guard let manager = m else {
                self.setVolumeCompletion?(PBSetGenericError.notConnected)
                return
            }
            
            manager.connectDevice(device: self, completion: { (error) in
                if let e = error {
                    self.setVolumeCompletion?(PBSetGenericError.connectionFail(error: e))
                }else{
                    self.discoverServices()
                }
            })
        @unknown default:
            break
        }
        
    }
    
    /// The function you call to try and find a `PBFinder`
    ///
    /// - Parameters:
    ///   - option: The options for finding the `PBFinder`. `shortRange` will find with a normal bluetooth range of about 40-50 feet. `longRange` will find with a range of ~100 feet but might take a little longer.
    ///   - m: The `PBBluetoothManager` that will help find the `PBFinder`. Required for `longRange` requests and for `shortRange` request when the `PBFinder` is not currently connected.
    ///   - completion: The completion that might contain the `PBFinderFindError` if the request failed.
    public func find(option: PBFinderFindOptions, withManager m: PBBluetoothManager?, completion: @escaping (_ findError: PBFinderFindError?) -> Void) {
        //Make sure we have a peripheral state
        guard let state = self.connectionState else {
            completion(PBFinderFindError.notConnected)
            return
        }
        //Set the Find completion
        self.findCompletion = completion
        //Set need to buzz
        self.needToBuzz = true
        //Set Buzz Option
        self.buzzType = option
        guard let manager = m else {
            self.findCompletion?(PBFinderFindError.notConnected)
            return
        }
        //Switch on the option
        print("***** Stat=\(state.rawValue), option=\(option)")
        switch option {
        case .shortRange:
            
            PBBroadcastManager.shared.stopLocalBeacon(self)
            //If Short Range initiate connection sequence check the state of the peripheral to see if we need to connect or not.
            switch state {
            case .connected:
                self.writeForBuzz()
            case .disconnected, .disconnecting, .connecting:
                print("***** .disconnected, .disconnecting, .connecting")
                manager.connectDevice(device: self, completion: { (error) in
                    if let e = error {
                        self.findCompletion?(PBFinderFindError.connectionFail(error: e))
                    }else{
                        self.discoverServices()
                        
                    }
                })
            @unknown default:
                break
            }
            
        case .longRange:

            //Switch on the State of the peripheral
            switch state {
            case .connected:
                self.writeForDisconnect()

                PBBroadcastManager.shared.setUpBeacon(withMajor: self.major, withMinor: self.minor, withQueue: nil)
                PBBroadcastManager.shared.startLocalBeacon()
            case .disconnected, .disconnecting, .connecting:
                //Start broadcasting the device region
                PBBroadcastManager.shared.setUpBeacon(withMajor: self.major, withMinor: self.minor, withQueue: nil)
                PBBroadcastManager.shared.startLocalBeacon()
                manager.connectDevice(device: self, completion: { (error) in
                    if let e = error {
                        print("connectDevice error: \(e)")
                        self.findCompletion?(PBFinderFindError.connectionFail(error: e))
                        self.findCompletion = nil
                        self.buzzType = nil
                        self.needToBuzz = false
                    }else{
                        self.discoverServices()
                    }
                })
            @unknown default:
                break
            }

        }
        
    }
    
    public func resetDevice(withManager m: PBBluetoothManager?, completion: @escaping (_ error: PBSetGenericError?) -> Void) {
        self.resetDevice = true
        guard let state = self.connectionState else {
            self.resetDeviceCompletion?(PBSetGenericError.notConnected)
            return
        }
        switch state {
        case .connecting, .disconnecting:
            self.resetDeviceCompletion?(PBSetGenericError.notConnected)
        case .connected:
            self.writeToReset()
        case .disconnected:
            guard let manager = m else {
                self.setJingleCompletion?(PBSetGenericError.notConnected)
                return
            }
            
            manager.connectDevice(device: self, completion: { (error) in
                if let e = error {
                    self.resetDeviceCompletion?(PBSetGenericError.connectionFail(error: e))
                }else{
                    self.discoverServices()
                }
            })
        default:
            return
        }
        
    }
    
    // MARK: - Processes
    @objc func writeForBuzz() {
        //See if we need to buzz
        guard self.needToBuzz else {
            //If not Return
            return
        }
        
        //Make sure we have the correct characteristic
        guard let c = self.data1Characteristic else {
            self.findCompletion?(PBFinderFindError.notConnected)
            return
        }
        
        //Make the value and write it
        let value = Data(bytes: UnsafePointer<UInt8>([UInt8(0x80),UInt8(0x01)]), count: 2 * MemoryLayout<UInt8>.size)
        print("    Write: \(value)")
        self.peripheral?.writeValue(value, for: c, type: CBCharacteristicWriteType.withResponse)
        
        
    }
    
    @objc func writeForDisconnect() {
        guard let c = self.data2Characteristic else {
            return
        }
        
        let value = Data(bytes: UnsafePointer<UInt8>([UInt8(0x01)]), count: MemoryLayout<UInt8>.size)
        print("    Write: \(value)")
        self.peripheral?.writeValue(value, for: c, type: CBCharacteristicWriteType.withResponse)
    }
    
    @objc func writeForDormant() {
        
        guard self.setDormant else {
            return
        }
        
        guard let c = self.data1Characteristic else {
            self.setDormantCompletion?(PBSetDormantError.notConnected)
            return
        }
        let byte0 = UInt8(0x04)
        let byte1 = UInt8(0x00)
        let byte2 = UInt8(0x00)
        let byte3 = UInt8(0x00)
        let byte4 = UInt8(0x00)
        let byte5 = UInt8(0x00)
        let byte6 = UInt8(0x01)
        let byteArrayDormant = [byte0, byte1 , byte2 , byte3 , byte4 , byte5 , byte6 ]
        
        let dormantData = Data(bytes: UnsafePointer<UInt8>(byteArrayDormant), count: 7 * MemoryLayout<UInt8>.size)
        print("    Write: \(dormantData)")
        self.peripheral?.writeValue(dormantData, for: c, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    @objc func writeForOTA() {
        
        guard self.setOTA else {
            return
        }
        
        guard let c = self.data1Characteristic else {
            self.setOTACompletion?(PBSetOTAError.notConnected)
            return
        }
        let byte0 = UInt8(0x08)
        let byte1 = UInt8(0x00)
        let byte2 = UInt8(0x00)
        let byte3 = UInt8(0x00)
        let byte4 = UInt8(0x00)
        let byte5 = UInt8(0x01)
        
        let byteArrayDormant = [byte0, byte1 , byte2 , byte3 , byte4 , byte5]
        
        let OTAData = Data(bytes: UnsafePointer<UInt8>(byteArrayDormant), count: 6 * MemoryLayout<UInt8>.size)
        print("    Write: \(OTAData)")
        self.peripheral?.writeValue(OTAData, for: c, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    @objc func writeForCancelBuzz() {
        
        guard self.setCancelBuzz else {
            return
        }
        
        PBBroadcastManager.shared.stopLocalBeacon(self)
        
        guard let c = self.data1Characteristic else {
            self.setCancelBuzzCompletion?(PBSetGenericError.notConnected)
            return
        }
        let byte0 = UInt8(0x02)
        let byte1 = UInt8(0x00)
        let byte2 = UInt8(0x00)
        let byte3 = UInt8(0x00)
        let byte4 = UInt8(0x00)
        let byte5 = UInt8(0x00)
        let byte6 = UInt8(0x00)
        let byte7 = UInt8(0x01)
        
        let byteArrayDormant = [byte0, byte1 , byte2 , byte3 , byte4 , byte5, byte6, byte7]
        
        let OTAData = Data(bytes: UnsafePointer<UInt8>(byteArrayDormant), count: 8 * MemoryLayout<UInt8>.size)
        print("    Write: \(OTAData)")
        self.peripheral?.writeValue(OTAData, for: c, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    @objc func writeForReboot() {
        
        guard self.setReboot else {
            return
        }
        
        guard let c = self.data1Characteristic else {
            self.setRebootCompletion?(PBSetGenericError.notConnected)
            return
        }
        let byte0 = UInt8(0x04)
        let byte1 = UInt8(0x00)
        let byte2 = UInt8(0x00)
        let byte3 = UInt8(0x00)
        let byte4 = UInt8(0x00)
        let byte5 = UInt8(0x00)
        let byte6 = UInt8(0x02)

        
        let byteArrayDormant = [byte0, byte1 , byte2 , byte3 , byte4 , byte5, byte6]
        
        let OTAData = Data(bytes: UnsafePointer<UInt8>(byteArrayDormant), count: 7 * MemoryLayout<UInt8>.size)
        print("    Write: \(OTAData)")
        self.peripheral?.writeValue(OTAData, for: c, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    @objc func writeForVolumeChange(VolumeIndex volIndex: Int) {
        
        guard self.setVolume else {
            return
        }
        
        guard let c = self.data1Characteristic else {
            self.setVolumeCompletion?(PBSetGenericError.notConnected)
            return
        }
        let byte0 = UInt8(0x02)
        let byte1 = UInt8(0x00)
        let byte2 = UInt8(0x00)
        let byte3 = UInt8(volIndex) //0-3

        
        let byteArrayDormant = [byte0, byte1 , byte2 , byte3 ]
        
        let OTAData = Data(bytes: UnsafePointer<UInt8>(byteArrayDormant), count: 4 * MemoryLayout<UInt8>.size)
        print("    Write: \(OTAData)")
        self.peripheral?.writeValue(OTAData, for: c, type: CBCharacteristicWriteType.withResponse)
        self.setVolumeValue = volIndex
        
    }
    
    @objc func writeForJingleChange(JingleIndex jingleIndex: Int) {
        
        guard self.setJingle else {
            return
        }
        
        guard let c = self.data1Characteristic else {
            self.setJingleCompletion?(PBSetGenericError.notConnected)
            return
        }
        
        //8 00 00 00 00 00 00 01 (hex)
        
        let byte0 = UInt8(0x08)
        let byte1 = UInt8(0x00)
        let byte2 = UInt8(0x00)
        let byte3 = UInt8(0x00)
        let byte4 = UInt8(0x00)
        let byte5 = UInt8(0x00)
        let byte6 = UInt8(0x00)
        let byte7 = UInt8(jingleIndex) //1-8 index 2 normal, index 8 zelda
        
        let byteArrayDormant = [byte0, byte1 , byte2 , byte3 , byte4 , byte5, byte6, byte7]
        
        let OTAData = Data(bytes: UnsafePointer<UInt8>(byteArrayDormant), count: 8 * MemoryLayout<UInt8>.size)
        print("    Write: \(OTAData)")
        self.peripheral?.writeValue(OTAData, for: c, type: CBCharacteristicWriteType.withResponse)
        self.setJingleValue = jingleIndex
    }
    
    public func writeToReset () {
        print("================\(#function)===================")
        guard self.resetDevice else {
            return
        }
        
        guard let c = self.data1Characteristic else {
            resetDeviceCompletion?(PBSetGenericError.notConnected)
            return
        }
        
        let byte0 = UInt8(0x08)
        let byte1 = UInt8(0x00)
        let byte2 = UInt8(0x00)
        let byte3 = UInt8(0x00)
        let byte4 = UInt8(0x00)
        let byte5 = UInt8(0x01)
        let byteArray = [byte0, byte1 , byte2 , byte3 , byte4 , byte5]
        let value = Data(bytes: UnsafePointer<UInt8>(byteArray), count: 6 * MemoryLayout<UInt8>.size)
        print("    Write: \(value)")
        self.peripheral?.writeValue(value, for: c, type: CBCharacteristicWriteType.withResponse)
        self.resetDevice = false
    }
    
    public func getBatteryPercentage(withManufacturerData data: Data) -> Double? {
        guard data.count > 14 else { // Small broadcast, battery info not included
            return nil
        }
        
        let firstRange = data.subdata(in: Range(uncheckedBounds: (lower: 12, upper: 12 + MemoryLayout<UInt8>.size)))
        let secondRange = data.subdata(in: Range(uncheckedBounds: (lower: 13, upper: 13 + MemoryLayout<UInt8>.size)))
        
        let leastSignificatnt = (firstRange as NSData).bytes.bindMemory(to: UInt8.self, capacity: firstRange.count).pointee
        let mostSignificant = (secondRange as NSData).bytes.bindMemory(to: UInt8.self, capacity: secondRange.count).pointee
        
        let volts = Int(mostSignificant) * 256 + Int(leastSignificatnt)
        
        let percentage = Double(volts - BatteryCapacityLevel.finderMin) / Double(BatteryCapacityLevel.finderMax - BatteryCapacityLevel.finderMin) * 100.0
        
        return percentage
    }
}



extension PBFinder1 {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("***** \(#function)")
        guard let services = peripheral.services else {
            print("***** no peripheral.services!")
            return
        }
        
        for s in services {
            print("***** s.uuid = \(s.uuid)")
            switch s.uuid {
            case finderServiceUUID:
                peripheral.discoverCharacteristics([data1CharacteristicUUID, data2CharacteristicUUID], for: s)
            default:
                return
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("***** PBFind \(#function)")
        guard let characteristics = service.characteristics else {
            return
        }
        
        
        for c in characteristics {
            switch c.uuid {
            case data2CharacteristicUUID:
                self.data2Characteristic = c
            case data1CharacteristicUUID:
                self.data1Characteristic = c
            default:
                return
            }
        }
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("***** PBFind \(#function)")
        if let e = error {
            print(e)
        }
        
        switch characteristic.uuid {
        case data2CharacteristicUUID:
            
            
           // self.needToWakeUp = false need to find when actually disconnected?
           if self.buzzType == .longRange && self.needToBuzz == true {
           //should something more happen to trigger TX?
            }
        case data1CharacteristicUUID:
            if let e = error {
                DispatchQueue.main.async {
                    self.findCompletion?(PBFinderFindError.bluetoothError(error: e))
                    self.setDormantCompletion?(PBSetDormantError.bluetoothError(error: e))
                    self.setJingleCompletion?(PBSetGenericError.bluetoothError(error: e))
                    self.setVolumeCompletion?(PBSetGenericError.bluetoothError(error: e))
                    self.setRebootCompletion?(PBSetGenericError.bluetoothError(error: e))
                    self.setCancelBuzzCompletion?(PBSetGenericError.bluetoothError(error: e))
                }
            }else{
                DispatchQueue.main.async {
                    if self.needToBuzz {
                        self.findCompletion?(nil)
                        self.needToBuzz = false
                    } else if self.setCancelBuzz {
                        self.setCancelBuzzCompletion?(nil)
                        self.setCancelBuzz = false
                    } else if self.setDormant {
                        self.setDormantCompletion?(nil)
                        self.setDormant = false
                    } else if self.setJingle {
                        self.setJingleCompletion?(nil)
                        self.setJingle = false
                        self.setJingleValue = 2
                    } else if self.setReboot {
                        self.setRebootCompletion?(nil)
                        self.setReboot = false
                    } else if self.setVolume {
                        self.setVolumeCompletion?(nil)
                        self.setVolume = false
                        self.setVolumeValue = 3
                    }
                    
                    self.buzzType = nil
                    self.needToWakeUp = false
                }

            }
        default:
            return
        }
        

    }
    
    
}


//MARK: Extension for class funcitons
extension PBFinder1 {
    class func getMajorMinor(fromData d: Data) -> (Int, Int)? {
    
        let majorRange = Range(uncheckedBounds: (2, 2 + 4))
        let majorSubdata = d.subdata(in: majorRange)
        let minorRange = Range(uncheckedBounds: (4, 4 + 2))
        let minorSubdata = d.subdata(in: minorRange)
        
        
        var major: UInt16 = 0
        majorSubdata.withUnsafeBytes( { (bytes: UnsafePointer<UInt16> ) in
            major = UInt16(bytes.pointee.bigEndian)
        })
        var minor: UInt16 = 0
        minorSubdata.withUnsafeBytes( { (bytes: UnsafePointer<UInt16> ) in
            minor = UInt16(bytes.pointee.bigEndian)
        })
        
        return (Int(major), Int(minor))
        
    }
}

// MARK: - PBBluetoothDevice

extension PBFinder1: PBBluetoothDevice {
    
    public func setBuzzVolume(volume: PBDeviceVolume, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        setVolume(withManager: PBBluetoothManager.shared, indexValue: volume.rawValue) { (error) in
            if let _ = error {
                completion(.failure(.couldntConnectDevice))
            } else {
                completion(.success(()))
            }
        }
    }
    
    public func buzz(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        find(option: .shortRange, withManager: PBBluetoothManager.shared) { (error) in
            if let _ = error {
                completion(.failure(.couldntConnectDevice))
            } else {
                completion(.success(()))
            }
        }
    }
    
    public func stopBuzz(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        setCancelBuzz(withManager: PBBluetoothManager.shared) { (error) in
            if let _ = error {
                completion(.failure(.couldntConnectDevice))
            } else {
                completion(.success(()))
            }
        }
    }
    
    public func setInDormantMode(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        setDormant(withManager: PBBluetoothManager.shared) { (error) in
            if let _ = error {
                completion(.failure(.couldntConnectDevice))
            } else {
                completion(.success(()))
            }
        }
    }
    
}

// MARK: - PBRebootableDevice

extension PBFinder1: PBRebootableDevice {
    
    public func reboot(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.setReboot(withManager: PBBluetoothManager.shared) { (error) in
            if let _ = error {
                completion(.failure(.couldntConnectDevice))
            } else {
                completion(.success(()))
            }
        }
    }
    
}
