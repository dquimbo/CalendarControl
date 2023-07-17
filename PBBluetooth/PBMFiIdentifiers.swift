//
//  PBMFiIdentifiers.swift
//  PBBluetooth
//
//  Created by Julian Astrada on 21/03/2022.
//  Copyright © 2022 Nick Franks. All rights reserved.
//

enum PBMFiIdentitifiers: UInt8 {
    case card = 0x02
    case clip = 0x03
    case tag = 0x04
    case white = 0x05
    case green = 0x06
    case rakTag = 0x0D
    case cardV2 = 0x22
    case clipV2 = 0x23
    case tagV2 = 0x24
    
    var deviceType: PBDeviceType {
        switch self {
        case .card:
            return .card
        case .clip:
            return .mfiClip
        case .tag:
            return .mfiTag
        case .white:
            return .mfiWhite
        case .green:
            return .mfiGreen
        case .rakTag:
            return .mfiR4KTag
        case .cardV2:
            return .mfiCardV2
        case .clipV2:
            return .mfiClipV2
        case .tagV2:
            return .mfiTagV2
        }
    }
}
