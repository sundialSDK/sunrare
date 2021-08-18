//
//  Device+Ext.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 03.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
    /// Gets the identifier from the system, such as "iPhone7,1".
    public static var identifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)

        let identifier = mirror.children.reduce("") { identifier, element in
          guard let value = element.value as? Int8, value != 0 else { return identifier }
          return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()
    
    static func isA12Chip() -> Bool {
        let id = self.identifier.lowercased()

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
