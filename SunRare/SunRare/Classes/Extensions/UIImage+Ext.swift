//
//  UIImage+Ext.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 05.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    static func placeholderArtwork() -> UIImage? {
        return UIImage(named: "placeholder_artwork", in: Bundle.current, with: nil)
    }
    func crop(rect: CGRect, scale: CGFloat) -> UIImage? {
        var rect = rect
        rect.origin.x *= scale
        rect.origin.y *= scale
        rect.size.width *= scale
        rect.size.height *= scale

        if let imageRef = cgImage?.cropping(to: rect) {
            return UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
}
