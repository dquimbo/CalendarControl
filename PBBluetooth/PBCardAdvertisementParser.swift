//
//  PBCardDataParser.swift
//  PBNetworking
//
//  Created by Jon Vogel on 12/2/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation


class PBCardAdvertisementParser: PBFinderAdvertisementParser {
    
    //MARK: Functions
    override internal func update(withAdvertisement data: [String : Any], manufacturerData: Data, device: PBDevice) {
        super.update(withAdvertisement: data, manufacturerData: manufacturerData, device: device)
        
        //Make sure that the lenght of the advertised data object is long enough for us to parse.
        guard manufacturerData.count >= 8, let card = device as? PBCard else {
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
        
        if let name = card.name {
            descString += "\(name): "
        }else{
            descString += "My BlackCard: " + (card.macAddress ?? "unknownMac")
        }
        
        
        
        switch actionSequence {
        case 0b0000:
            descString += "Action Sequence: Never Pressed \(String(actionSequence, radix: 2)), "
            if card.buttonState != .none {
                card.buttonState = .none
            }
        case 0b0001:
            descString += "Action Sequence: Just Pressed \(String(actionSequence, radix: 2)), "
        case 0b0010:
            descString += "Action Sequence: Resetting \(String(actionSequence, radix: 2)), "
            if card.buttonState == .none {
                switch buttonPush {
                case 0b01:
                    card.buttonState = .singlePress
                case 0b10:
                    card.buttonState = .longPress
                case 0b11:
                    card.buttonState = .doublePress
                default:
                    break
                }
                
            }
            else if card.buttonState != .none {
                card.buttonState = .none
            }
            return
        case 0b0100:
            descString += "Action Sequence: Pressed Before \(String(actionSequence, radix: 2)), "
            if card.buttonState != .none {
                card.buttonState = .none
            }
        default:
            descString += "Action Sequence: Unknown \(String(actionSequence, radix: 2)), "
            if card.buttonState != .none {
                card.buttonState = .none
            }
        }
        
        switch buzzing{
        case 0b0:
            descString += "Buzzing: No \(String(buzzing, radix: 2)), "
            if card.buzzState != .iddle{
                card.buzzState = .iddle
            }
        case 0b1:
            descString += "Buzzing: Yes \(String(buzzing, radix: 2)), "
            if card.buzzState != .buzzing{
                card.buzzState = .buzzing
            }
        default:
            descString += "Buzzing: Unknown \(String(buzzing, radix: 2)), "
            if card.buzzState != .iddle{
                card.buzzState = .iddle
            }
        }
        
        switch adState {
        case 0b0:
            descString += "Ad State: High \(String(adState, radix: 2)), "
            if card.advertisementState != .high{
                card.advertisementState = .high
            }
        case 0b1:
            descString += "Ad State: Low \(String(adState, radix: 2)), "
            if card.advertisementState != .low{
                card.advertisementState = .low
            }
        default:
            descString += "Ad State: Unknown \(String(adState, radix: 2)), "
            if card.advertisementState != .unknown{
                card.advertisementState = .unknown
            }
        }
        
        switch buttonPush {
        case 0b00:
            descString += "Button: Static \(String(buttonPush, radix: 2))"
            if card.buttonState != .none {
                card.buttonState = .none
            }
        case 0b01:
            descString += "Button: Pressed \(String(buttonPush, radix: 2))"
            if card.buttonState != .singlePress {
                card.buttonState = .singlePress
            }
        case 0b10:
            descString += "Button: Held \(String(buttonPush, radix: 2))"
            if card.buttonState != .longPress {
                card.buttonState = .longPress
            }
        case 0b11:
            descString += "Button: Double Tapped \(String(buttonPush, radix: 2))"
            if card.buttonState != .doublePress {
                card.buttonState = .doublePress
            }
        default:
            descString += "Button: Unknown \(String(buttonPush, radix: 2))"
            if card.buttonState != .none {
                card.buttonState = .none
            }
        }
    }
    
    
}
