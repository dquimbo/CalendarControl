//
//  PBMFiClipV2.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 26/04/2023.
//  Copyright © 2023 Nick Franks. All rights reserved.
//

import UIKit

public class PBMFiClipV2: PBMFiClip, PBMFiDeviceV2 {
    
    public var FMNAvailable: Bool = false
    
    public var FMDAvailable: Bool = false
    
    public var FMNProvisioned: Bool = false
    
    public var FMDProvisioned: Bool = false
    
    public var networkActiveMSB: Bool = false
    
    public var networkActiveLSB: Bool = false
    
    public var smpUnlocked: Bool = false
    
    override init(withMacAddress address: String) {
        super.init(withMacAddress: address)
        
        self.deviceType = .mfiClipV2
        self.dataParser = PBMFiClipV2AdvertisementParser()
    }
    
}
