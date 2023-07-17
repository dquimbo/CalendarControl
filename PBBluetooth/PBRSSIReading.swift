//
//  PBRSSI.swift
//  PBNetworking
//
//  Created by Jon Vogel on 12/9/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation


///Class that represents a single RSSI recording for a given 'PBDevice'.
public class PBRSSIReading: PBHistory {
    ///The RSSI that was recorded
    public internal(set) var rssi: Int!
    ///The system accuracy that was associated with this RSSI reading
    public internal(set) var accuracy: Double!
    
    
    internal init(_ RSSI: Int, _ accuracy: Double, timeStamp ts: Date) {
        super.init(timeStamp: ts)
        self.rssi = RSSI
        self.accuracy = accuracy
    }
    
}
