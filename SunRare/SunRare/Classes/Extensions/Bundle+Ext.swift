//
//  Bundle+Ext.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 05.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation

extension Bundle {
    static let current: Bundle = {
        let bundle = Bundle(for: ARWallArtworkControl.self)
        return bundle
//        let path = bundle.bundlePath
//        return Bundle(path: path + "/sunrare.bundle")!
    }()
}
