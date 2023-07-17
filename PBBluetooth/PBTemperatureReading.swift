//
//  PBTemperatureReading.swift
//  PBNetworking
//
//  Created by Jon Vogel on 12/9/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation


public class PBTemperatureReading: PBHistory {
    ///The raw temperature reading from the `PBDevice`
    public private(set) var rawTemp: Int!
    ///The calibrated temperature readign from the `PBDevice`
    public private(set) var calibratedTemp: Int?
    
    
    internal init(withRawTemp t: Int, calibrationOffSet c: Int) {
        super.init(timeStamp: Date())
        self.rawTemp = t
        self.calibratedTemp = rawTemp + c
    }
    
    
}
