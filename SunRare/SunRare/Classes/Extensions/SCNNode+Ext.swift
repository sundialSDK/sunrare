//
//  SCNNode+Ext.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 05.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import SceneKit

extension SCNNode {
    static func planeNode(plane: SCNPlane, contents: Any?) -> SCNNode {
        let material = SCNMaterial()
        material.diffuse.contents = contents
        material.isDoubleSided = true
                
        //flip image
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(1,-1,1)
        material.diffuse.wrapT = .repeat // or translate contentsTransform by (0,1,0)
        
        plane.materials = [material]
        return SCNNode(geometry: plane)
    }
}
