//
//  Device+Ext.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 03.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import DeviceKit

extension Device {
    static func isA12Chip() -> Bool {
        let id = Device.identifier.lowercased()
        
        //grab clear version string
        var clearVersion = id
        if id.contains("iphone") {
            clearVersion = id.replacingOccurrences(of: "iphone", with: "")
        } else if id.contains("ipad") {
            clearVersion = id.replacingOccurrences(of: "ipad", with: "")
        } else {
            return false
        }

        //grab major version
        guard let major = clearVersion.components(separatedBy: ",").first,
              let version = Int(major) else {
            return false
        }
                    
        //iphone11 / ipad11 with a12 chip
        return version >= 11
    }
}
