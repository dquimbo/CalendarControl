//
//  Extensions.swift
//  PBNetworking
//
//  Created by Jon Vogel on 11/18/16.
//  Copyright © 2016 Jon Vogel. All rights reserved.
//

import Foundation
import CoreBluetooth

public extension Date {
    /// Gets you the 'Time ago' from now in human readable format. Very useful for 'Last Seen' text in a UI.
    func timeAgoSinceNow() -> String {
        
        let components = self.dateComponents()
        guard let yearDiff = components.year, let monthDiff = components.month, var weekDiff = components.day, let dayDiff = components.day, let hourDiff = components.hour, let minuteDiff = components.minute, let secondDiff = components.second else {
            return ""
        }
        weekDiff = weekDiff / 7
        
        var s = ""
        
        if yearDiff > 0 {
            s += NSLocalizedString("TimeAgoYear", comment:"")
            return s
        }else if monthDiff > 0 {
            s += "\(monthDiff) "
            if monthDiff == 1 {
                s += NSLocalizedString("TimeAgoMonth", comment:"")
            }else{
                s += NSLocalizedString("TimeAgoMonths", comment:"")
            }
            return s
        }else if weekDiff > 0 {
            s += "\(weekDiff) "
            if weekDiff == 1 {
                s += NSLocalizedString("TimeAgoWeek", comment:"")
            }else{
                s += NSLocalizedString("TimeAgoWeeks", comment:"")
            }
            return s
        }else if dayDiff > 0{
            s += "\(dayDiff) "
            if dayDiff == 1 {
                s += NSLocalizedString("TimeAgoDay", comment:"")
            }else{
                s += NSLocalizedString("TimeAgoDays", comment:"")
            }
            return s
        }else if hourDiff > 0{
            s += "\(hourDiff) "
            if hourDiff == 1 {
                s += NSLocalizedString("TimeAgoHour", comment:"")
            }else{
                s += NSLocalizedString("TimeAgoHours", comment:"")
            }
            return s
        }else if minuteDiff > 0{
            s += "\(minuteDiff) "
            if minuteDiff == 1 {
                s += NSLocalizedString("TimeAgoMinute", comment:"")
            }else{
                s += NSLocalizedString("TimeAgoMinutes", comment:"")
            }
            return s
        }else if secondDiff > 0 {
            if secondDiff < 5 {
                s += NSLocalizedString("TimeAgoJustnow", comment:"")
            }else{
                s += "\(secondDiff) " + NSLocalizedString("TimeAgoSeconds", comment:"")
            }
            return s
        }else{
            s += NSLocalizedString("TimeAgoJustnow", comment:"")
            return s
        }
    }
    
    private func dateComponents() -> DateComponents {
        let calander = NSCalendar.current
        let set: Set<Calendar.Component> = [.second, .minute, .hour, .day, .month, .year]
        return calander.dateComponents(set, from: self, to: Date())
    }
}

extension CBCentralManager {
    @objc var stateString: String {
        switch self.state {
        case .poweredOn:
            return "POWERED ON"
        case .poweredOff:
            return "POWERED OFF"
        case .resetting:
            return "RESETTING"
        case .unauthorized:
            return "UNAUTHORIZED"
        case .unknown:
            return "UNKNOWN"
        case .unsupported:
            return "UNSUPPORTED"
        @unknown default:
            return "UNSUPPORTED"
        }
    }
}


extension CBPeripheral {
    @objc var stateString: String {
        switch self.state{
        case .connected:
            return "CONNECTED"
        case .connecting:
            return "CONNECTING"
        case .disconnected:
            return "DISCONNECTED"
        case .disconnecting:
            return "DISCONNECTING"
        @unknown default:
            return "UNKNOWN"
        }
    }
}
