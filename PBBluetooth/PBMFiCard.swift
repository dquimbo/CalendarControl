//
//  MFiCard.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 21/03/2022.
//  Copyright © 2022 Nick Franks. All rights reserved.
//

public class PBMFiCard: PBMFiClip {
    
    override init(withMacAddress address: String) {
        super.init(withMacAddress: address)
        
        self.deviceType = .mfiCard
    }
    
}
