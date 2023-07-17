//
//  PBMFiGreen.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 01/02/2023.
//  Copyright © 2023 Nick Franks. All rights reserved.
//

import UIKit

class PBMFiGreen: PBMFiCard {
    
    override init(withMacAddress address: String) {
        super.init(withMacAddress: address)
        self.deviceType = .mfiGreen
    }
    
}
