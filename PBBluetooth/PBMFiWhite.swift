//
//  PBMFiTag.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 31/01/2023.
//  Copyright © 2023 Nick Franks. All rights reserved.
//

import UIKit

class PBMFiWhite: PBMFiCard {

    override init(withMacAddress address: String) {
        super.init(withMacAddress: address)
        self.deviceType = .mfiWhite
    }
    
}
