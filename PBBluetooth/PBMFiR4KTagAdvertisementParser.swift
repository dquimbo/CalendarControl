//
//  PBMFiR4KTagAdvertisementParser.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 13/07/2023.
//  Copyright © 2023 Nick Franks. All rights reserved.
//

import UIKit
import CoreBluetooth

class PBMFiR4KTagAdvertisementParser: PBAdvertisementParser {
    
    override func update(withAdvertisement data: [String : Any], manufacturerData: Data, device: PBDevice) {
        super.update(withAdvertisement: data, manufacturerData: manufacturerData, device: device)
        
        guard let mfiR4KTag = device as? PBMFiR4KTag else { return }
        
        mfiR4KTag.broadcastingName = data[CBAdvertisementDataLocalNameKey] as? String
        
        let buttonState = manufacturerData[4]
        
        switch buttonState {
        case 0:
            mfiR4KTag.buttonState = .none
        case 1:
            mfiR4KTag.buttonState = .singlePress
        case 2:
            mfiR4KTag.buttonState = .doublePress
        case 3:
            mfiR4KTag.buttonState = .triplePress
        case 4:
            mfiR4KTag.buttonState = .quadruplePress
        case 5:
            mfiR4KTag.buttonState = .quintuplePress
        case 6:
            mfiR4KTag.buttonState = .longPress
        case 7:
            mfiR4KTag.buttonState = .doublePressPlusHold
        case 8:
            mfiR4KTag.buttonState = .triplePressPlusHold
        default:
            break
        }
        
        let bitArray = bits(fromBytes: manufacturerData[6])
        
        mfiR4KTag.bondingState = bitArray.last == .zero ? .unbonded : .bonded
        mfiR4KTag.firmwareVersion = Int(manufacturerData[3])
        mfiR4KTag.txPower = Int(manufacturerData[5])
        mfiR4KTag.stationaryMinutes = Int(manufacturerData[7])
    }
    
}
