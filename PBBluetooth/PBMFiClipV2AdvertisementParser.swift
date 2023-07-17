//
//  PBMFiClipV2AdvertisementParser.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 13/07/2023.
//  Copyright © 2023 Nick Franks. All rights reserved.
//

import UIKit
import CoreBluetooth

class PBMFiClipV2AdvertisementParser: PBAdvertisementParser {
    
    override func update(withAdvertisement data: [String : Any], manufacturerData: Data, device: PBDevice) {
        super.update(withAdvertisement: data, manufacturerData: manufacturerData, device: device)
        
        guard let mfiDeviceV2 = device as? PBMFiDeviceV2 else { return }
        
        mfiDeviceV2.broadcastingName = data[CBAdvertisementDataLocalNameKey] as? String
        
        let buttonState = manufacturerData[4]
        
        switch buttonState {
        case 0:
            mfiDeviceV2.buttonState = .none
        case 1:
            mfiDeviceV2.buttonState = .singlePress
        case 2:
            mfiDeviceV2.buttonState = .doublePress
        case 3:
            mfiDeviceV2.buttonState = .triplePress
        case 4:
            mfiDeviceV2.buttonState = .quadruplePress
        case 5:
            mfiDeviceV2.buttonState = .quintuplePress
        case 6:
            mfiDeviceV2.buttonState = .longPress
        case 7:
            mfiDeviceV2.buttonState = .doublePressPlusHold
        case 8:
            mfiDeviceV2.buttonState = .triplePressPlusHold
        default:
            break
        }
        
        let bitArray = bits(fromBytes: manufacturerData[11])
        
        mfiDeviceV2.FMNAvailable = bitArray[7] == .one
        mfiDeviceV2.FMDAvailable = bitArray[6] == .one
        mfiDeviceV2.FMNProvisioned = bitArray[5] == .one
        mfiDeviceV2.FMDProvisioned = bitArray[4] == .one
        mfiDeviceV2.networkActiveMSB = bitArray[3] == .one
        mfiDeviceV2.networkActiveLSB = bitArray[2] == .one
        mfiDeviceV2.smpUnlocked = bitArray[1] == .one
        mfiDeviceV2.bondingState = bitArray[0] == .zero ? .bonded : .unbonded
    }
    
}
