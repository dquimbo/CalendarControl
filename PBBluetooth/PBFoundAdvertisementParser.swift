//
//  PBFoundDataParser.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 28/01/2021.
//  Copyright © 2021 Nick Franks. All rights reserved.
//

import UIKit

class PBFoundAdvertisementParser: PBAdvertisementParser {
    
    //MARK: Functions
    
    override func update(withAdvertisement data: [String : Any], manufacturerData: Data, device: PBDevice) {
        super.update(withAdvertisement: data, manufacturerData: manufacturerData, device: device)

        //Make sure that the lenght of the advertised data object is long enough for us to parse.
        guard manufacturerData.count >= 8, let found = device as? PBFound else {
            return
        }
        
        let actionRange = Range(uncheckedBounds: (7,7 + MemoryLayout<UInt8>.size))
        let alertLevelSubdata = manufacturerData.subdata(in: actionRange)
        var alertLevelRawData: UInt8 = 0
        
        alertLevelSubdata.withUnsafeBytes( { (bytes: UnsafePointer<UInt8> ) in
            alertLevelRawData = UInt8(bytes.pointee)
        })
        
        let actionSequence = (alertLevelRawData & 0b11110000) >> 4
        let buzzing = (alertLevelRawData & 0b00001000) >> 3
        let adState = (alertLevelRawData & 0b00000100) >> 2
        let buttonPush = (alertLevelRawData & 0b00000011)
        
        
        
        let buttonCount = (alertLevelRawData & 0b00000011)
        
        
        
        var descString = ""
        
        if let name = found.name {
            descString += "\(name): "
        }else{
            descString += "My BlackCard: " + (found.macAddress ?? "unknownMac")
        }
        
        
        
        switch actionSequence {
        case 0b0000:
            descString += "Action Sequence: Never Pressed \(String(actionSequence, radix: 2)), "
            found.buttonState = .none
        case 0b0001:
            descString += "Action Sequence: Just Pressed \(String(actionSequence, radix: 2)), "
        case 0b0010:
            descString += "Action Sequence: Resetting \(String(actionSequence, radix: 2)), "
            if found.buttonState == PBButtonState.none {
                switch buttonPush {
                case 0b01:
                    found.buttonState = .singlePress
                case 0b10:
                    found.buttonState = .longPress
                case 0b11:
                    found.buttonState = .doublePress
                default:
                    break
                }
                
            } else {
                found.buttonState = .none
            }
            return
        case 0b0100:
            descString += "Action Sequence: Pressed Before \(String(actionSequence, radix: 2)), "
            found.buttonState = .none
        default:
            descString += "Action Sequence: Unknown \(String(actionSequence, radix: 2)), "
            found.buttonState = .none
        }
        
        switch buzzing{
        case 0b0:
            descString += "Buzzing: No \(String(buzzing, radix: 2)), "
            if found.buzzState != .iddle{
                found.buzzState = .iddle
            }
        case 0b1:
            descString += "Buzzing: Yes \(String(buzzing, radix: 2)), "
            if found.buzzState != .buzzing{
                found.buzzState = .buzzing
            }
        default:
            descString += "Buzzing: Unknown \(String(buzzing, radix: 2)), "
            if found.buzzState != .iddle{
                found.buzzState = .iddle
            }
        }
        
        switch adState {
        case 0b0:
            descString += "Ad State: High \(String(adState, radix: 2)), "
            if found.advertisementState != .high{
                found.advertisementState = .high
            }
        case 0b1:
            descString += "Ad State: Low \(String(adState, radix: 2)), "
            if found.advertisementState != .low{
                found.advertisementState = .low
            }
        default:
            descString += "Ad State: Unknown \(String(adState, radix: 2)), "
            if found.advertisementState != .unknown{
                found.advertisementState = .unknown
            }
        }
        
        switch buttonPush {
        case 0b00:
            descString += "Button: Static \(String(buttonPush, radix: 2))"
            found.buttonState = .none
        case 0b01:
            descString += "Button: Pressed \(String(buttonPush, radix: 2))"
            if found.buttonState != .singlePress {
                found.buttonState = .singlePress
            }
        case 0b10:
            descString += "Button: Held \(String(buttonPush, radix: 2))"
            found.buttonState = .longPress
        case 0b11:
            descString += "Button: Double Tapped \(String(buttonPush, radix: 2))"
            if found.buttonState != .doublePress {
                found.buttonState = .doublePress
            }
        default:
            descString += "Button: Unknown \(String(buttonPush, radix: 2))"
            found.buttonState = .none
        }
    }
    
    
}
