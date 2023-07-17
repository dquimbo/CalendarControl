//
//  PBMFiDeviceV2.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 26/04/2023.
//  Copyright © 2023 Nick Franks. All rights reserved.
//

import UIKit

public protocol PBMFiDeviceV2: PBMFiDevice {
    
    var FMNAvailable: Bool { get set }
    
    var FMDAvailable: Bool { get set }
    
    var FMNProvisioned: Bool { get set }
    
    var FMDProvisioned: Bool { get set }
    
    var networkActiveMSB: Bool { get set }
    
    var networkActiveLSB: Bool { get set }
    
    var smpUnlocked: Bool { get set }

}
