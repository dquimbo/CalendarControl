//
//  PBCard.swift
//  PBNetworking
//
//  Created by Jon Vogel on 11/29/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation



/// Class that represents Pebblebee's PB Card product.
public class PBFinder2: PBFinder1 {

    /// This represents the refresh rate we use to broadcast the updates. We wait this amount of seconds before *attempting* (Smart Mode check will take place too) to fire a Left Behind alert/
    override public var refreshRateInternal: TimeInterval {
        return 380
    }
        
    @objc internal required init(withAMacAddress mac: String, andMajor maj: Int, andMinor min: Int) {
        super.init(withAMacAddress: mac,andMajor: maj, andMinor: min)
        self.dataParser = PBFinder2AdvertisementParser()
        self.deviceType = .finder2
    }
  
}

