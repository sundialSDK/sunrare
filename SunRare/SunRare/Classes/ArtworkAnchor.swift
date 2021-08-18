//
//  ArtworkAnchor.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 09.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import ARKit

class ArtworkAnchor: ARAnchor {
    var model: ArtworkModel
    var zoom: Float
    
    init(transform: simd_float4x4, model: ArtworkModel) {
        self.model = model
        self.zoom = 1
        super.init(transform: transform)
    }
        
    required init?(coder: NSCoder) {
        //load model
        if let data = coder.decodeObject(forKey: "artworkModelData") as? Data {
            do {
                self.model = try JSONDecoder().decode(ArtworkModel.self, from: data)
            }
            catch {
                return nil
            }
        } else {
            return nil
        }
        
        //zoom
        self.zoom = coder.decodeFloat(forKey: "nodeZoom")
        
        super.init(coder: coder)
    }
    
    // Encode your custom property using a key to be decoded
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        
        //save
        if let data = try? JSONEncoder().encode(model) {
            aCoder.encode(data, forKey: "artworkModelData")
        }
        aCoder.encode(zoom, forKey: "nodeZoom")
    }
    
    // this is required to maintain your custom properties as ARKit refreshes
    required init(anchor: ARAnchor) {
        let other = anchor as! ArtworkAnchor
        self.model = other.model
        self.zoom = other.zoom
        super.init(anchor: anchor)
    }

   
    override class var supportsSecureCoding: Bool {
        return true
    }
    
}
