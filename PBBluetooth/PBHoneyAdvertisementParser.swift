//
//  PBHoneyDataParser.swift
//  PBNetworking
//
//  Created by Jon Vogel on 12/2/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation


class PBHoneyAdvertisementParser: PBAdvertisementParser {
    
    //MARK: Functions
    
    override func update(withAdvertisement data: [String : Any], manufacturerData: Data, device: PBDevice) {
        super.update(withAdvertisement: data, manufacturerData: manufacturerData, device: device)

        //Make sure that the lenght of the advertised data object is long enough for us to parse.
        guard manufacturerData.count >= 8, let honey = device as? PBHoney else {
            return
        }
        
        let buttonPressRange = Range(uncheckedBounds: (6, 6 + MemoryLayout<UInt8>.size))
        let buttonPressSubData = manufacturerData.subdata(in: buttonPressRange)
        var buttonPressRawData: UInt8 = 0
        
        buttonPressSubData.withUnsafeBytes({ (data: UnsafePointer<UInt8> ) in
            buttonPressRawData = UInt8(data.pointee)
        })
        
        switch buttonPressRawData {
        case 0:
            honey.buttonState = .none
        case 1:
            if honey.buttonState != .singlePress {
                honey.buttonState = .singlePress
            }
        default:
            honey.buttonState = .none
        }
        
        let firmwareModelRange = Range(uncheckedBounds: (7, 7 + MemoryLayout<UInt8>.size))
        let firmwareModelSubData = manufacturerData.subdata(in: firmwareModelRange)
        
        var firmwareModelRawData: UInt8 = 0
        
        firmwareModelSubData.withUnsafeBytes({ (data: UnsafePointer<UInt8>) in
            firmwareModelRawData = UInt8(data.pointee)
        })
        
        if let firmwareVersion = PBHoneyFirmwareVersion(rawValue: Int(firmwareModelRawData)) {
            if honey.firmwareVersion != firmwareVersion {
                honey.firmwareVersion = firmwareVersion
            }
        }        
    }

}

