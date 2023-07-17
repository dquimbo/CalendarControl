//
//  PBCard.swift
//  PBNetworking
//
//  Created by Jon Vogel on 11/29/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation



/// Class that represents Pebblebee's PB Card product.
public class PBCard: PBFinder1 {
    
    @objc internal required init(withAMacAddress mac: String, andMajor maj: Int, andMinor min: Int) {
        super.init(withAMacAddress: mac,andMajor: maj, andMinor: min)
        self.dataParser = PBCardAdvertisementParser()
        self.deviceType = .card
    }
    
    // MARK: - Override methods of PBDevice

    public override func getBatteryPercentage(withManufacturerData data: Data) -> Double? {
        guard data.count > 14 else { // Small broadcast, battery info not included
            return nil
        }
        
        let firstRange = data.subdata(in: Range(uncheckedBounds: (lower: 12, upper: 12 + MemoryLayout<UInt8>.size)))
        let secondRange = data.subdata(in: Range(uncheckedBounds: (lower: 13, upper: 13 + MemoryLayout<UInt8>.size)))
        
        let leastSignificatnt = (firstRange as NSData).bytes.bindMemory(to: UInt8.self, capacity: firstRange.count).pointee
        let mostSignificant = (secondRange as NSData).bytes.bindMemory(to: UInt8.self, capacity: secondRange.count).pointee
        
        let volts = Int(mostSignificant) * 256 + Int(leastSignificatnt)
        
        let percentage = Double(volts - BatteryCapacityLevel.cardMin) / Double(BatteryCapacityLevel.cardMax - BatteryCapacityLevel.cardMin) * 100.0
        
        return percentage
    }
    
}

