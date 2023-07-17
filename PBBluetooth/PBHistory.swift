//
//  PBHistory.swift
//  PBNetworking
//
//  Created by Jon Vogel on 12/9/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation


///Base class for items that `PBDevice`'s need to keep track of
public class PBHistory: Hashable{
    ///The system time the record was created in seconds from 1970.
    public private(set) var timeStampSeconds: Double = 0
    ///The system time the record was created in milli seconds from 1970.
    public private(set) var timeStampMilliseconds: Double = 0
    ///The system time the record was created
    public private(set) var timeStamp: Date!
    ///Hash key for comparability
    public var hashValue: Int {
        get{
            return Int(self.timeStampSeconds)
        }
    }
    
    //Convenience init for internal use. Consumers of the framewok should never need to construct these objects
    internal init(timeStamp ts: Date) {
        self.timeStamp = ts
        self.timeStampSeconds = self.timeStamp.timeIntervalSince1970
        self.timeStampMilliseconds = self.timeStampSeconds * 1000
    }
    
    ///Hashability function as required by the `Hashable` protocol
    public static func == (lhs: PBHistory, rhs: PBHistory) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
