//
//  PBMFiR4KTag.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 01/02/2023.
//  Copyright © 2023 Nick Franks. All rights reserved.
//

import UIKit
import CoreBluetooth

let R4K_TAG_CHARID_PWD = CBUUID(string: "2C0A")
let R4K_TAG_CHARID_ADMIN = CBUUID(string: "2C0B")
let R4K_TAG_CHARID_ADVINT = CBUUID(string: "2C0C")
let R4K_TAG_CHARID_CHALLENGE = CBUUID(string: "2C09")
let R4K_TAG_CHARID_JINGLE = CBUUID(string: "2C0E")
let R4K_TAG_CHARID_JINGLE_DURATION = CBUUID(string: "2C0F")
let R4K_TAG_CHARID_ACCTHR = CBUUID(string: "2C11")
let R4K_TAG_CHARID_ACCTIME = CBUUID(string: "2C12")
let R4K_TAG_CHARID_TXPWR = CBUUID(string: "2C0D")
let R4K_TAG_CHARID_LEDCOLOR = CBUUID(string: "2C10")

public enum PBMFiR4KTagJingle: UInt8 {
    case standard = 0x00
    case loud = 0x01
}

public class PBMFiR4KTag: PBMFiClip {
    
    public var firmwareVersion: Int?
    public var txPower: Int?
    public var stationaryMinutes: Int?
    
    internal var writingToQuietBuzz = false
    internal var quietBuzzCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    
    internal var writingToSilentBuzz = false
    internal var silentBuzzCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    
    internal var challengeTokenCompletion: ((Result<Data, PBBluetoothError>) -> Void)?
    internal var readingChallengeToken = false
    
    internal var getAdvertisementIntervalCompletion: ((Result<Int, PBBluetoothError>) -> Void)?
    internal var readingAdvertisementInterval = false
    
    internal var setAdvertisementIntervalCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    internal var advertisementIntervalToSet: Int?
    internal var settingAdvertisementInterval = false
    
    internal var getJingleSelectedCompletion: ((Result<PBMFiR4KTagJingle, PBBluetoothError>) -> Void)?
    internal var readingJingleSelected = false
    
    internal var setJingleCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    internal var jingleToSet: PBMFiR4KTagJingle?
    internal var settingJingle = false
    
    internal var getJingleDurationCompletion: ((Result<Int, PBBluetoothError>) -> Void)?
    internal var readingJingleDuration = false
    
    internal var setJingleDurationCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    internal var jingleDurationToSet: Int?
    internal var settingJingleDuration = false
    
    internal var getAccThresholdCompletion: ((Result<Int, PBBluetoothError>) -> Void)?
    internal var readingAccThreshold = false
    
    internal var setAccThresholdCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    internal var accThresholdToSet: Int?
    internal var settingAccThreshold = false
    
    internal var getAccTimeCompletion: ((Result<Int, PBBluetoothError>) -> Void)?
    internal var readingAccTime = false
    
    internal var setAccTimeCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    internal var accTimeToSet: Int?
    internal var settingAccTime = false
    
    internal var getTxPowerCompletion: ((Result<Int, PBBluetoothError>) -> Void)?
    internal var readingTxPower = false
    
    internal var setTxPowerCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    internal var txPowerToSet: Int?
    internal var settingTxPower = false
    
    internal var getLEDColorCompletion: ((Result<String, PBBluetoothError>) -> Void)?
    internal var readingLEDColor = false
    
    internal var setLEDColorCompletion: ((Result<Void, PBBluetoothError>) -> Void)?
    internal var ledColorToSet: [UInt8]?
    internal var settingLEDColor = false
    
    /// Bonding variables
    private var writingPassword = false
    private var ownerPassword: Data?
    private var writingForOwnerMode = false
    private var waitingForButtonPress = false
    
    internal override var data2Characteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.needToBuzz {
                    self.writeForBuzz()
                } else if self.needToStopBuzz {
                    self.writeForStopBuzz()
                } else if self.writingToQuietBuzz {
                    self.writeToQuietBuzz()
                } else if self.writingToSilentBuzz {
                    self.writeToSilentBuzz()
                }
            }
        }
    }
    
    internal var data3Characteristic: CBCharacteristic?
    
    internal var passwordCharacteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.writingPassword {
                    self.writePasswordForOwnerMode()
                }
            }
        }
    }
    
    internal var adminCharacteristic: CBCharacteristic?
    
    internal var challengeCharacteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.readingChallengeToken {
                    self.readChallengeToken()
                }
            }
        }
    }
    
    internal var advertisementCharacteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.readingAdvertisementInterval {
                    self.readAdvertisementInterval()
                } else if self.settingAdvertisementInterval {
                    self.writeToSetAdvertisementInterval()
                }
            }
        }
    }
    
    internal var jingleCharacteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.readingJingleSelected {
                    self.readJingleSelected()
                } else if self.settingJingle {
                    self.writeToSetJingle()
                }
            }
        }
    }
    
    internal var jingleDurationCharacteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.readingJingleDuration {
                    self.readJingleDuration()
                } else if self.settingJingleDuration {
                    self.writeToSetJingleDuration()
                }
            }
        }
    }
    
    internal var accThresholdCharacteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.readingAccThreshold {
                    self.readAccThreshold()
                } else if self.settingAccThreshold {
                    self.writeToSetAccThreshold()
                }
            }
        }
    }
    
    internal var accTimeCharacteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.readingAccTime {
                    self.readAccTime()
                } else if self.settingAccTime {
                    self.writeToSetAccTime()
                }
            }
        }
    }
    
    internal var txPowerCharacteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.readingTxPower {
                    self.readTxPower()
                } else if self.settingTxPower {
                    self.writeToSetTxPower()
                }
            }
        }
    }
    
    internal var ledColorCharacteristic: CBCharacteristic? {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.readingLEDColor {
                    self.readLEDColor()
                } else if self.settingLEDColor{
                    self.writeToSetLEDColor()
                }
            }
        }
    }
    
    override init(withMacAddress address: String) {
        super.init(withMacAddress: address)
        
        self.deviceType = .mfiR4KTag
        self.dataParser = PBMFiR4KTagAdvertisementParser()
    }
    
    override public func discoverServices() {
        self.peripheral?.discoverServices([r4kTagServiceUUID])
    }
    
    override  public func triggerBondFromDevice(password: Data?, completion: @escaping (PBBondTriggerResult) -> Void) {
        guard let ownerPassword = password else {
            completion(.passwordRequired)
            
            return
        }
        
        self.bondCompletion = { result in
            DispatchQueue.main.async {
                self.writingPassword = false
                self.writingForOwnerMode = false
                self.bonding = false
                
                completion(result)
            }
        }
        
        self.writingPassword = true
        self.ownerPassword = ownerPassword
        
        guard let state = self.connectionState else {
            bondCompletion?(.error(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            bondCompletion?(.error(.couldntConnectDevice))
        case .connected:
            writePasswordForOwnerMode()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.bondCompletion?(.error(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            bondCompletion?(.error(.couldntDetermineDeviceState))
        }
    }
    
    override public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            switch service.uuid {
            case r4kTagServiceUUID:
                peripheral.discoverCharacteristics([data1CharacteristicUUID,
                                                    data2CharacteristicUUID,
                                                    data3CharacteristicUUID,
                                                    R4K_TAG_CHARID_PWD,
                                                    R4K_TAG_CHARID_ADMIN,
                                                    R4K_TAG_CHARID_ADVINT,
                                                    R4K_TAG_CHARID_JINGLE,
                                                    R4K_TAG_CHARID_JINGLE_DURATION,
                                                    R4K_TAG_CHARID_CHALLENGE,
                                                    R4K_TAG_CHARID_ACCTHR,
                                                    R4K_TAG_CHARID_ACCTIME,
                                                    R4K_TAG_CHARID_TXPWR,
                                                    R4K_TAG_CHARID_LEDCOLOR], for: service)
            default:
                return
            }
        }
    }
    
    override public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
            // Data
            case data1CharacteristicUUID:
                self.data1Characteristic = characteristic
            case data2CharacteristicUUID:
                self.data2Characteristic = characteristic
            case data3CharacteristicUUID:
                self.data3Characteristic = characteristic
                peripheral.setNotifyValue(true, for: self.data3Characteristic!)
            // Password
            case R4K_TAG_CHARID_PWD:
                self.passwordCharacteristic = characteristic
            // Admin
            case R4K_TAG_CHARID_ADMIN:
                self.adminCharacteristic = characteristic
            // Challenge
            case R4K_TAG_CHARID_CHALLENGE:
                self.challengeCharacteristic = characteristic
            // Advertisement Interval
            case R4K_TAG_CHARID_ADVINT:
                self.advertisementCharacteristic = characteristic
            // Jingle
            case R4K_TAG_CHARID_JINGLE:
                self.jingleCharacteristic = characteristic
            // Jingle Duration
            case R4K_TAG_CHARID_JINGLE_DURATION:
                self.jingleDurationCharacteristic = characteristic
            // Accelerometer Threshold
            case R4K_TAG_CHARID_ACCTHR:
                self.accThresholdCharacteristic = characteristic
            // Accelerometer Time
            case R4K_TAG_CHARID_ACCTIME:
                self.accTimeCharacteristic = characteristic
            // Tx Power
            case R4K_TAG_CHARID_TXPWR:
                self.txPowerCharacteristic = characteristic
            // LED Color
            case R4K_TAG_CHARID_LEDCOLOR:
                self.ledColorCharacteristic = characteristic
            default:
                return
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        DispatchQueue.main.async {
            switch characteristic.uuid {
            case data3CharacteristicUUID:
                guard let data = characteristic.value, error == nil else {
                    if self.writingPassword {
                        self.bondCompletion?(.error(.errorReadingValueFromCharacteristic))
                    }
                    
                    return
                }
                
                if self.writingPassword {
                    self.writingPassword = false
                    
                    if data.hexEncodedString() == "0a2c00" {
                        self.writeToStartOwnerMode()
                    } else {
                        self.bondCompletion?(.passwordNotAccepted)
                    }
                } else if self.writingForOwnerMode {
                    self.writingForOwnerMode = false
                    self.waitingForButtonPress = true
                    
                    if data.hexEncodedString() == "0b2c00" {
                        self.bondCompletion?(.deviceButtonPressRequired)
                    } else {
                        self.bondCompletion?(.error(.errorWrittingInCharacteristic))
                    }
                } else if self.waitingForButtonPress, data.hexEncodedString() == "03" {
                    self.waitingForButtonPress = false
                    self.bonding = true
                    
                    super.readForBonding()
                } else {
                    // Button presses
                    switch data.hexEncodedString() {
                    case "10":
                        self.buttonState = .none
                    case "11":
                        self.buttonState = .singlePress
                    case "12":
                        self.buttonState = .doublePress
                    case "13":
                        self.buttonState = .triplePress
                    case "14":
                        self.buttonState = .quadruplePress
                    case "15":
                        self.buttonState = .quintuplePress
                    case "16":
                        self.buttonState = .longPress
                    case "17":
                        self.buttonState = .doublePressPlusHold
                    case "18":
                        self.buttonState = .triplePressPlusHold
                    default:
                        break
                    }
                }
            case R4K_TAG_CHARID_CHALLENGE:
                guard let data = characteristic.value, error == nil else {
                    if self.readingChallengeToken {
                        self.challengeTokenCompletion?(.failure(.errorReadingValueFromCharacteristic))
                    }
                    
                    return
                }
                
                self.challengeTokenCompletion?(.success(data))
            case R4K_TAG_CHARID_ADVINT:
                guard let data = characteristic.value?.last, error == nil else {
                    if self.readingAdvertisementInterval {
                        self.getAdvertisementIntervalCompletion?(.failure(.errorReadingValueFromCharacteristic))
                    }
                    
                    return
                }
                
                self.getAdvertisementIntervalCompletion?(.success(Int(data)))
            case R4K_TAG_CHARID_JINGLE:
                guard let data = characteristic.value?.last, error == nil, let jingle = PBMFiR4KTagJingle(rawValue: data) else {
                    if self.readingJingleSelected {
                        self.getJingleSelectedCompletion?(.failure(.errorReadingValueFromCharacteristic))
                    }
                    
                    return
                }
                
                self.getJingleSelectedCompletion?(.success(jingle))
            case R4K_TAG_CHARID_JINGLE_DURATION:
                guard let data = characteristic.value?.last, error == nil else {
                    if self.readingJingleDuration {
                        self.getJingleDurationCompletion?(.failure(.errorReadingValueFromCharacteristic))
                    }
                    
                    return
                }
                
                self.getJingleDurationCompletion?(.success(Int(data)))
            case R4K_TAG_CHARID_ACCTHR:
                guard let data = characteristic.value?.last, error == nil else {
                    if self.readingAccThreshold {
                        self.getAccThresholdCompletion?(.failure(.errorReadingValueFromCharacteristic))
                    }
                    
                    return
                }
                
                self.getAccThresholdCompletion?(.success(Int(data)))
            case R4K_TAG_CHARID_ACCTIME:
                guard let data = characteristic.value?.last, error == nil else {
                    if self.readingAccTime {
                        self.getAccTimeCompletion?(.failure(.errorReadingValueFromCharacteristic))
                    }
                    
                    return
                }
                
                self.getAccTimeCompletion?(.success(Int(data)))
            case R4K_TAG_CHARID_TXPWR:
                guard let data = characteristic.value?.last, error == nil else {
                    if self.readingTxPower {
                        self.getTxPowerCompletion?(.failure(.errorReadingValueFromCharacteristic))
                    }
                    
                    return
                }
                
                let signedValue: Int = data < 128 ? Int(data) : Int(data) - 256
                
                self.getTxPowerCompletion?(.success(signedValue))
            case R4K_TAG_CHARID_LEDCOLOR:
                guard let data = characteristic.value, error == nil else {
                    if self.readingLEDColor {
                        self.getLEDColorCompletion?(.failure(.errorReadingValueFromCharacteristic))
                    }
                    
                    return
                }
                
                self.getLEDColorCompletion?(.success(data.hexEncodedString()))
            default:
                break
            }
        }
    }
    
    public override func getBatteryPercentage(withManufacturerData data: Data) -> Double? {
        guard data.count > 6 else { return nil }
        
        return Double((data[6] << 1) >> 1)
    }
    
}

// MARK: - Bonding specific methods

extension PBMFiR4KTag {
    
    internal func writePasswordForOwnerMode() {
        guard self.writingPassword, let characteristic = self.passwordCharacteristic, let password = ownerPassword else {
            self.bondCompletion?(.error(.couldntConnectDevice))
            
            return
        }
        
        self.peripheral?.writeValue(password, for: characteristic, type: .withoutResponse)
    }
    
    internal func writeToStartOwnerMode() {
        self.writingForOwnerMode = true
        
        guard let characteristic = adminCharacteristic else {
            self.bondCompletion?(.error(.couldntConnectDevice))
            
            return
        }
        
        self.peripheral?.writeValue(Data([0x01]), for: characteristic, type: .withoutResponse)
    }
    
}

// MARK: - MFi R4K Tag Specific features

extension PBMFiR4KTag {
    
    /// Attemps to buzz quietly the device
    /// - Parameter completion: The completion block returns Void on success or PBBluetoothError on failure
    public func quietBuzz(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.quietBuzzCompletion = completion
        self.writingToQuietBuzz = true
        
        guard let state = self.connectionState else {
            quietBuzzCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            quietBuzzCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeToQuietBuzz()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.quietBuzzCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            quietBuzzCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func writeToQuietBuzz() {
        guard self.writingToQuietBuzz, let characteristic = self.data2Characteristic else {
            self.quietBuzzCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        self.peripheral?.writeValue(Data([0x06]), for: characteristic, type: .withoutResponse)
        
        self.writingToQuietBuzz = false
        
        self.quietBuzzCompletion?(.success(()))
    }
    
    /// Attemps to buzz silently the device
    /// - Parameter completion: The completion block returns Void on success or PBBluetoothError on failure
    public func silentBuzz(completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.silentBuzzCompletion = completion
        self.writingToSilentBuzz = true
        
        guard let state = self.connectionState else {
            silentBuzzCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            silentBuzzCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeToSilentBuzz()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.silentBuzzCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            silentBuzzCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func writeToSilentBuzz() {
        guard self.writingToSilentBuzz, let characteristic = self.data2Characteristic else {
            self.silentBuzzCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        self.peripheral?.writeValue(Data([0x07]), for: characteristic, type: .withoutResponse)
        
        self.writingToSilentBuzz = false
        
        self.silentBuzzCompletion?(.success(()))
    }
    
    /// Reads the Challenge Token
    /// - Parameter completion: Returns a result with Data on success or PBBluetoothError on failure
    public func getChallengeToken(completion: @escaping (Result<Data, PBBluetoothError>) -> Void) {
        self.challengeTokenCompletion = completion
        self.readingChallengeToken = true
        
        guard let state = self.connectionState else {
            challengeTokenCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            challengeTokenCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            readChallengeToken()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.challengeTokenCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            challengeTokenCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func readChallengeToken() {
        guard self.readingChallengeToken,
              let characteristic = self.challengeCharacteristic,
              let peripheral = self.peripheral else {
            self.challengeTokenCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        peripheral.readValue(for: characteristic)
        
        self.readingChallengeToken = false
    }
    
    
    /// Retrieves the advertisement interval, with a value between 1 and 19
    /// - Parameter completion: The completion block returns an Int on success or a PBBluetoothError on failure
    public func getAdvertisementInterval(completion: @escaping (Result<Int, PBBluetoothError>) -> Void) {
        self.getAdvertisementIntervalCompletion = completion
        self.readingAdvertisementInterval = true
        
        guard let state = self.connectionState else {
            getAdvertisementIntervalCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            getAdvertisementIntervalCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            readAdvertisementInterval()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.getAdvertisementIntervalCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            getAdvertisementIntervalCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func readAdvertisementInterval() {
        guard self.readingAdvertisementInterval,
              let characteristic = self.advertisementCharacteristic,
              let peripheral = self.peripheral else {
            self.getAdvertisementIntervalCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        peripheral.readValue(for: characteristic)
        
        self.readingAdvertisementInterval = false
    }
    
    /// Sets the advertisement interval, it accepts a value of 1 to 19 corresponding to 0.5 sec interval.
    /// A value of 4, for example, corresponds to 2 seconds.
    /// - Parameters:
    ///   - advertisementInterval: The advertisement interval to be set.
    ///   - completion: The completion block returns Void on success or a PBBluetoothError on failure
    public func setAdvertisementInterval(advertisementInterval: Int, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.setAdvertisementIntervalCompletion = completion
        self.advertisementIntervalToSet = advertisementInterval
        self.settingAdvertisementInterval = true
        
        guard advertisementInterval >= 1, advertisementInterval <= 19 else {
            setAdvertisementIntervalCompletion?(.failure(.valueNotAccepted))
            return
        }
        
        guard let state = self.connectionState else {
            setAdvertisementIntervalCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            setAdvertisementIntervalCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeToSetAdvertisementInterval()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.setAdvertisementIntervalCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            setAdvertisementIntervalCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func writeToSetAdvertisementInterval() {
        guard self.settingAdvertisementInterval,
              let characteristic = self.advertisementCharacteristic,
              let interval = self.advertisementIntervalToSet else {
            self.setAdvertisementIntervalCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        self.peripheral?.writeValue(Data([UInt8(interval)]), for: characteristic, type: .withoutResponse)
        
        self.settingAdvertisementInterval = false
        
        self.setAdvertisementIntervalCompletion?(.success(()))
    }
    
    
    /// Retrieves the jingle selected
    /// - Parameter completion: The completion block returns a PBMFiR4KTagJingle on success or a PBBluetoothError on failure
    public func getJingleSelected(completion: @escaping (Result<PBMFiR4KTagJingle, PBBluetoothError>) -> Void) {
        self.getJingleSelectedCompletion = completion
        self.readingJingleSelected = true
        
        guard let state = self.connectionState else {
            getJingleSelectedCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            getJingleSelectedCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            readJingleSelected()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.getJingleSelectedCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            getJingleSelectedCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func readJingleSelected() {
        guard self.readingJingleSelected,
              let characteristic = self.jingleCharacteristic,
              let peripheral = self.peripheral else {
            self.getJingleSelectedCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        peripheral.readValue(for: characteristic)
        
        self.readingJingleSelected = false
    }
    
    /// Sets the current jingle on the device
    /// - Parameters:
    ///   - jingle: The jingle to set on the device
    ///   - completion: The completion block returns Void on success or a PBBluetoothError on failure
    public func setJingle(jingle: PBMFiR4KTagJingle, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.setJingleCompletion = completion
        self.jingleToSet = jingle
        self.settingJingle = true
        
        guard let state = self.connectionState else {
            setJingleCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            setJingleCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeToSetJingle()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.setJingleCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            setJingleCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func writeToSetJingle() {
        guard self.settingJingle,
              let characteristic = self.jingleCharacteristic,
              let jingleToSet = self.jingleToSet else {
            self.setJingleCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        self.peripheral?.writeValue(Data([jingleToSet.rawValue]), for: characteristic, type: .withoutResponse)
        
        self.settingJingle = false
        
        self.setJingleCompletion?(.success(()))
    }
    
    /// Retrieves the jingle duration in intervals with 5 seconds increase, from 1 seconds to 24.
    /// A value of 10 corresponds to 50 seconds, for example.
    /// - Parameter completion: The completion block returns Int on success or a PBBluetoothError on failure
    public func getJingleDuration(completion: @escaping (Result<Int, PBBluetoothError>) -> Void) {
        self.getJingleDurationCompletion = completion
        self.readingJingleDuration = true
        
        guard let state = self.connectionState else {
            getJingleDurationCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            getJingleDurationCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            readJingleDuration()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.getJingleDurationCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            getJingleDurationCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func readJingleDuration() {
        guard self.readingJingleDuration,
              let characteristic = self.jingleDurationCharacteristic,
              let peripheral = self.peripheral else {
            self.getJingleDurationCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        peripheral.readValue(for: characteristic)
        
        self.readingJingleDuration = false
    }
    
    /// Sets the new jingle duration, using intervals of 5 seconds increases. From 1 to 24.
    /// Setting a value of 10 will correspond to a duration of 50 seconds.
    /// - Parameters:
    ///   - jingleDuration: The new jingle duration
    ///   - completion: The completion block returns Void on success or a PBBluetoothError on failure
    public func setJingleDuration(jingleDuration: Int, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.setJingleDurationCompletion = completion
        self.jingleDurationToSet = jingleDuration
        self.settingJingleDuration = true
        
        guard jingleDuration >= 1, jingleDuration <= 24 else {
            setJingleDurationCompletion?(.failure(.valueNotAccepted))
            return
        }
        
        guard let state = self.connectionState else {
            setJingleDurationCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            setJingleDurationCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeToSetJingleDuration()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.setJingleDurationCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            setJingleDurationCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func writeToSetJingleDuration() {
        guard self.settingJingleDuration,
              let characteristic = self.jingleDurationCharacteristic,
              let duration = self.jingleDurationToSet else {
            self.setJingleDurationCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        self.peripheral?.writeValue(Data([UInt8(duration)]), for: characteristic, type: .withoutResponse)
        
        self.settingJingleDuration = false
        
        self.setJingleDurationCompletion?(.success(()))
    }
    
    /// Retrieves the accelerometer threshold
    /// - Parameter completion: The completion block returns Int on success or a PBBluetoothError on failure
    public func getAccThreshold(completion: @escaping (Result<Int, PBBluetoothError>) -> Void) {
        self.getAccThresholdCompletion = completion
        self.readingAccThreshold = true
        
        guard let state = self.connectionState else {
            getAccThresholdCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            getAccThresholdCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            readAccThreshold()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.getAccThresholdCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            getAccThresholdCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func readAccThreshold() {
        guard self.readingAccThreshold,
              let characteristic = self.accThresholdCharacteristic,
              let peripheral = self.peripheral else {
            self.getAccThresholdCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        peripheral.readValue(for: characteristic)
        
        self.readingAccThreshold = false
    }
    
    /// Sets the accelerometer threshold level, from 1 (high sensibility) to 10 (low sensibility).
    /// - Parameters:
    ///   - accThreshold: New thresold to be set.
    ///   - completion: The completion block returns Void on success or a PBBluetoothError on failure
    public func setAccThreshold(accThreshold: Int, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.setAccThresholdCompletion = completion
        self.accThresholdToSet = accThreshold
        self.settingAccThreshold = true
        
        guard accThreshold >= 1, accThreshold <= 10 else {
            setAccThresholdCompletion?(.failure(.valueNotAccepted))
            return
        }
        
        guard let state = self.connectionState else {
            setAccThresholdCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            setAccThresholdCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeToSetAccThreshold()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.setAccThresholdCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            setAccThresholdCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func writeToSetAccThreshold() {
        guard self.settingAccThreshold,
              let characteristic = self.accThresholdCharacteristic,
              let threshold = self.accThresholdToSet else {
            self.setAccThresholdCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        self.peripheral?.writeValue(Data([UInt8(threshold)]), for: characteristic, type: .withoutResponse)
        
        self.settingAccThreshold = false
        
        self.setAccThresholdCompletion?(.success(()))
    }
    
    /// Retrieves the accelerometer time
    /// - Parameter completion: The completion block returns Int on success or a PBBluetoothError on failure
    public func getAccTime(completion: @escaping (Result<Int, PBBluetoothError>) -> Void) {
        self.getAccTimeCompletion = completion
        self.readingAccTime = true
        
        guard let state = self.connectionState else {
            getAccTimeCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            getAccTimeCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            readAccTime()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.getAccTimeCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            getAccTimeCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func readAccTime() {
        guard self.readingAccTime,
              let characteristic = self.accTimeCharacteristic,
              let peripheral = self.peripheral else {
            self.getAccTimeCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        peripheral.readValue(for: characteristic)
        
        self.readingAccTime = false
    }
    
    /// Sets the new accelerometer time
    /// - Parameters:
    ///   - time: Time to be set.
    ///   - completion: The completion block returns Void on success or a PBBluetoothError on failure
    public func setAccTime(time: Int, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.setAccTimeCompletion = completion
        self.accTimeToSet = time
        self.settingAccTime = true
        
        guard time >= 1, time <= 20 else {
            setAccTimeCompletion?(.failure(.valueNotAccepted))
            return
        }
        
        guard let state = self.connectionState else {
            setAccTimeCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            setAccTimeCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeToSetAccTime()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.setAccTimeCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            setAccTimeCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func writeToSetAccTime() {
        guard self.settingAccTime,
              let characteristic = self.accTimeCharacteristic,
              let time = self.accTimeToSet else {
            self.setAccTimeCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        self.peripheral?.writeValue(Data([UInt8(time)]), for: characteristic, type: .withoutResponse)
        
        self.settingAccTime = false
        
        self.setAccTimeCompletion?(.success(()))
    }
    
    
    /// Reads Tx Power
    /// - Parameter completion: The completion block returns Int on success or a PBBluetoothError on failure
    public func getTxPower(completion: @escaping (Result<Int, PBBluetoothError>) -> Void) {
        self.getTxPowerCompletion = completion
        self.readingTxPower = true
        
        guard let state = self.connectionState else {
            getTxPowerCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            getTxPowerCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            readTxPower()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.getTxPowerCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            getTxPowerCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func readTxPower() {
        guard self.readingTxPower,
              let characteristic = self.txPowerCharacteristic,
              let peripheral = self.peripheral else {
            self.getTxPowerCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        peripheral.readValue(for: characteristic)
        
        self.readingTxPower = false
    }
    
    /// Sets the new value for Tx Power
    /// - Parameters:
    ///   - txPower: The Tx Power to be set.
    ///   - completion: The completion block returns Void on success or a PBBluetoothError on failure
    public func setTxPower(txPower: Int, completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.setTxPowerCompletion = completion
        self.txPowerToSet = txPower
        self.settingTxPower = true
        
        guard let state = self.connectionState else {
            setTxPowerCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            setTxPowerCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeToSetTxPower()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.setTxPowerCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            setTxPowerCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func writeToSetTxPower() {
        guard self.settingTxPower,
              let characteristic = self.txPowerCharacteristic,
              let time = self.txPowerToSet else {
            self.setTxPowerCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        let unsignedByte = time >= 0 ? UInt8(time) : UInt8(256 + time)
        
        self.peripheral?.writeValue(Data([unsignedByte]), for: characteristic, type: .withoutResponse)
        
        self.settingTxPower = false
        
        self.setTxPowerCompletion?(.success(()))
    }
    
    public func getLEDColor(completion: @escaping (Result<String, PBBluetoothError>) -> Void) {
        self.getLEDColorCompletion = completion
        self.readingLEDColor = true
        
        guard let state = self.connectionState else {
            getLEDColorCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            getLEDColorCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            readLEDColor()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.getLEDColorCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            getLEDColorCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func readLEDColor() {
        guard self.readingLEDColor,
              let characteristic = self.ledColorCharacteristic,
              let peripheral = self.peripheral else {
            self.getLEDColorCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        peripheral.readValue(for: characteristic)
        
        self.readingLEDColor = false
    }
    
    public func setLEDColor(ledColor: [UInt8], completion: @escaping (Result<Void, PBBluetoothError>) -> Void) {
        self.setLEDColorCompletion = completion
        self.ledColorToSet = ledColor
        self.settingLEDColor = true
        
        guard ledColor.count == 4 else {
            setLEDColorCompletion?(.failure(.valueNotAccepted))
            return
        }
        
        guard let state = self.connectionState else {
            setLEDColorCompletion?(.failure(.couldntDetermineDeviceState))
            return
        }
        
        switch state {
        case .connecting, .disconnecting:
            setLEDColorCompletion?(.failure(.couldntConnectDevice))
        case .connected:
            writeToSetLEDColor()
        case .disconnected:
            PBBluetoothManager.shared.connectDevice(device: self, completion: {[weak self] (error) in
                if error != nil {
                    self?.setLEDColorCompletion?(.failure(.couldntConnectDevice))
                } else {
                    self?.discoverServices()
                }
           })
        default:
            setLEDColorCompletion?(.failure(.couldntDetermineDeviceState))
        }
    }
    
    func writeToSetLEDColor() {
        guard self.settingLEDColor,
              let characteristic = self.ledColorCharacteristic,
              let color = self.ledColorToSet else {
            self.setLEDColorCompletion?(.failure(.couldntConnectDevice))
            return
        }
        
        self.peripheral?.writeValue(Data(color), for: characteristic, type: .withoutResponse)
        
        self.settingLEDColor = false
        
        self.setLEDColorCompletion?(.success(()))
    }
    
}
