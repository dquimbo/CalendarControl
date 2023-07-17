//
//  PBLocationHistory.swift
//  PBNetworking
//
//  Created by Jon Vogel on 12/9/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation
import CoreLocation

///Class that represents a single location that a given 'PBDevice' was seen at.
public class PBLocationReading: PBHistory {
    ///The Location object associated with the record. Convenient for making `MKMapItems`
    public var location: CLLocation!
    ///The `LocationHistory` condensed as a [String: AnyObject] dictionary. You can easily turn this into JSON as referenced in [this StackOverflow answer](http://stackoverflow.com/questions/28325268/convert-array-to-json-string-in-swift/34055555#34055555). The keys for the items in the dictionary can be found in the `PBLocationHistoryKeys` enumeration.
    public var JSONPiece: [String: AnyObject] {
        return [PBLocationHistoryKey.timestampKey.rawValue: self.timeStampMilliseconds as AnyObject, PBLocationHistoryKey.latitudeKey.rawValue: self.location.coordinate.latitude as AnyObject, PBLocationHistoryKey.longitudeKey.rawValue: self.location.coordinate.longitude as AnyObject]
    }
    
    public override var hashValue: Int{
        get{
            return Int(self.location.coordinate.latitude + self.location.coordinate.longitude + self.timeStampSeconds)
        }
    }
    
    
    internal init(withLocation loc: CLLocation) {
        super.init(timeStamp: loc.timestamp)
        self.location = loc
    }
    
}
