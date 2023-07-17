//
//  PBDeviceType.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 23/03/2022.
//  Copyright © 2022 Nick Franks. All rights reserved.
//

import UIKit

public enum PBDeviceType: Int {
    /// Legacy
    case honey = 1
    case finder = 5
    case finder2 = 13
    case card = 11
    /// Cellular
    case found = 14
    /// MFi
    case mfiCard = 16
    case mfiClip = 17
    case mfiTag = 18
    case mfiWhite = 19
    case mfiGreen = 20
    case mfiR4KTag = 21
    /// MFi V2
    case mfiCardV2 = 22
    case mfiClipV2 = 23
    case mfiTagV2 = 24
    /// Other
    case unknown = -1
    
    public var isMFI: Bool {
        switch self {
        case .mfiCard,
             .mfiClip,
             .mfiTag,
             .mfiWhite,
             .mfiGreen,
             .mfiR4KTag,
             .mfiClipV2,
             .mfiCardV2,
             .mfiTagV2:
            return true
        case .honey,
                .finder,
                .finder2,
                .card,
                .found,
                .unknown:
            return false
        }
    }
    
    public var isCellular: Bool {
        switch self {
        case .found:
            return true
        default:
            return false
        }
    }
    
    public var nameType: String {
        switch self {
        case .card:
            return "BlackCard"
        case .finder:
            return "Finder"
        case .finder2:
            return "Finder 2.0"
        case .honey:
            return "Honey"
        case .found:
            return "Found"
        case .mfiCard, .mfiCardV2:
            return "Card"
        case .mfiClip, .mfiClipV2:
            return "Clip"
        case .mfiTag, .mfiTagV2:
            return "Tag"
        case .mfiWhite:
            return "White"
        case .mfiGreen:
            return "Green"
        case .mfiR4KTag:
            return "R4K Tag"
        case .unknown:
            return "Unknown"
        }
    }
}
