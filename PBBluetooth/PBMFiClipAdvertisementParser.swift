//
//  PBMFiClipAdvertisementParser.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 13/07/2023.
//  Copyright © 2023 Nick Franks. All rights reserved.
//

import UIKit
import CoreBluetooth

class PBMFiClipAdvertisementParser: PBAdvertisementParser {
    
    override func update(withAdvertisement data: [String : Any], manufacturerData: Data, device: PBDevice) {
        super.update(withAdvertisement: data, manufacturerData: manufacturerData, device: device)
        
        guard let mfiDevice = device as? PBMFiDevice else { return }
        
        mfiDevice.broadcastingName = data[CBAdvertisementDataLocalNameKey] as? String
                        
        let buttonState = manufacturerData[4]

        switch buttonState {
        case 0:
            mfiDevice.buttonState = .none
        case 1:
            mfiDevice.buttonState = .singlePress
        case 2:
            mfiDevice.buttonState = .doublePress
        case 3:
            mfiDevice.buttonState = .triplePress
        case 4:
            mfiDevice.buttonState = .quadruplePress
        case 5:
            mfiDevice.buttonState = .quintuplePress
        case 6:
            mfiDevice.buttonState = .longPress
        case 7:
            mfiDevice.buttonState = .doublePressPlusHold
        case 8:
            mfiDevice.buttonState = .triplePressPlusHold
        default:
            break
        }
        
        mfiDevice.bondingState = PBBondingState(rawValue: manufacturerData[11]) ?? .unknown
    }

}
