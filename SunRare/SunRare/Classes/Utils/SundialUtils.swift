//
//  SundialUtils.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 04.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

extension Float {
    func toRadians() -> Float {
        return self * Float.pi / 180
    }
    func toDegrees() -> Float {
        return Float(180/Double.pi) * self
    }
}
extension CGFloat {
    func toRadians() -> CGFloat {
        return self * CGFloat.pi / 180
    }
    func toDegrees() -> CGFloat {
        return CGFloat(180/Double.pi) * self
    }
}


extension SCNVector3 {
    static func position(from itm: simd_float4x4) -> SCNVector3 {
        return SCNVector3(itm.columns.3.x, itm.columns.3.y, itm.columns.3.z)
    }
    static func position(from simdPos: simd_float3) -> SCNVector3 {
        return SCNVector3(simdPos.x, simdPos.y, simdPos.z)
    }
}

extension ARSCNView {
    func raycastResult(from pt: CGPoint, allowing: ARRaycastQuery.Target) -> [ARRaycastResult] {
        if let query = raycastQuery(from: pt, allowing: allowing, alignment: .vertical) {
            return session.raycast(query)
        }
        return []
    }
    
    func convertToScreenPoint(loc: SCNVector3, parent: SCNNode) -> CGPoint {
        let pos1 = self.scene.rootNode.convertPosition(loc, from: parent)
        let vec3 = self.projectPoint(pos1)
        return CGPoint(x: CGFloat( vec3.x ), y: CGFloat( vec3.y ))
    }
}
