//
//  PBMFiTagV2.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 26/04/2023.
//  Copyright © 2023 Nick Franks. All rights reserved.
//

import UIKit

public class PBMFiTagV2: PBMFiClipV2 {
    
    override init(withMacAddress address: String) {
        super.init(withMacAddress: address)
        self.deviceType = .mfiTagV2
    }

}
