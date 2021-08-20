//
//  ArtworkNode.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 04.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class ArtworkNode: SCNNode {
    private(set) var model: ArtworkModel
    private(set) var arrowNode: SCNNode
    private(set) var imageBgNode: SCNNode
    private(set) var imageNode: SCNNode
    private(set) var reorderIconNode: SCNNode
    private(set) var linkIconNode: SCNNode
    private(set) var zoomIconNode: SCNNode
    
    private var imgView: UIImageView?
    
    var state: ArtworkState = .none {
        didSet {
            updateByState()
        }
    }
    
    init(model: ArtworkModel, contentInfo: [ArtworkSubNodeType: Any]) {
        self.model = model
        
        //set correct size
        let max = max(model.contentSize.width, model.contentSize.height)
        let realSize = CGSize(width: model.contentSize.width/max, height: model.contentSize.height/max)
        
        //config bg node
        let scale: CGFloat = 0.75
        let bgPlane = SCNPlane(width: realSize.width * scale, height: realSize.height * scale)
        self.imageBgNode = SCNNode.planeNode(plane: bgPlane, contents: UIColor(white: 196/255, alpha: 0.33))
        self.imageBgNode.position.z += 0.001
        
        //config main image node
        let plane = SCNPlane(width: bgPlane.width * scale, height: bgPlane.height * scale)
        self.imageNode = SCNNode.planeNode(plane: plane, contents: contentInfo[.artworkPlaceholder])
            
        //config arrow node
        let arrowPlane = SCNPlane(width: 0.05, height: 0.05)
        self.arrowNode = SCNNode.planeNode(plane: arrowPlane, contents: contentInfo[.arrow] ?? UIColor.clear)
        self.arrowNode.position.y -= Float(bgPlane.height / 2) + Float(arrowPlane.height / 2)
        
        //place icon node
        let linkIconPlane = SCNPlane(width: 0.05, height: 0.05)
        self.linkIconNode = SCNNode.planeNode(plane: linkIconPlane, contents: contentInfo[.link] ?? UIColor.clear)
        self.linkIconNode.position.y += Float(bgPlane.height / 2) + Float(linkIconPlane.height / 2)
        self.linkIconNode.position.x -= Float(plane.width / 2) - Float(linkIconPlane.width / 2)
        
        //place reorder node
        let reorderIconPlane = SCNPlane(width: 0.05, height: 0.05)
        self.reorderIconNode = SCNNode.planeNode(plane: reorderIconPlane, contents: contentInfo[.reorder] ?? UIColor.clear)
        self.reorderIconNode.position.y = self.linkIconNode.position.y
        self.reorderIconNode.position.x += Float(plane.width / 2) - Float(reorderIconPlane.width / 2)
                
        //place zoom node
        let zoomIconPlane = SCNPlane(width: 0.05, height: 0.05)
        self.zoomIconNode = SCNNode.planeNode(plane: zoomIconPlane, contents: contentInfo[.zoom] ?? UIColor.clear)
        self.zoomIconNode.position.x += Float(bgPlane.width / 2) + Float(zoomIconPlane.width)
        
        super.init()
        
        //add childs
        addChildNode(imageBgNode)
        addChildNode(imageNode)
        addChildNode(arrowNode)
        addChildNode(linkIconNode)
        addChildNode(reorderIconNode)
        addChildNode(zoomIconNode)
        
        //load content
        loadContent(url: URL(string: model.contentLink))
        
        //force reset
        updateByState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateByState() {
        imageBgNode.isHidden = state != .placing
        arrowNode.isHidden = state == .none
        reorderIconNode.isHidden = state != .selected
        linkIconNode.isHidden = state != .selected
    }
    
    private func loadContent(url: URL?) {
        guard let tmp = url else { return }
        
        //usefull props
        let sz = model.contentSize
        
        switch model.contentType {
        case .img:
            //load content in bg
            DispatchQueue.global().async {
                guard let data = try? Data(contentsOf: tmp),
                      let img = UIImage(data: data)?.cgImage
                else { return }
                
                //fill content
                DispatchQueue.main.async { [weak self] in
                    self?.imageNode.geometry?.materials.first?.diffuse.contents = img
                }
            }
        case .gif:
            //load content in bg
            DispatchQueue.global().async {
                guard let data = try? Data(contentsOf: tmp),
                      let img = UIImage.gif(data: data)
                else { return }
                
                //fill content
                DispatchQueue.main.async { [weak self] in
                    //use image view to handle correctly animations
                    let tmp = UIImageView(frame: CGRect(origin: .zero, size: sz))
                    tmp.image = img
                    self?.imgView = tmp

                    //use image view layer as contents
                    self?.imageNode.geometry?.materials.first?.diffuse.contents = tmp.layer
                }
            }
        default:
            break
        }
    }
    
    func subNode(by type: ArtworkSubNodeType) -> SCNNode {
        switch type {
        case .artworkPlaceholder:
            return imageNode
        case .arrow:
            return arrowNode
        case .link:
            return linkIconNode
        case .reorder:
            return reorderIconNode
        case .zoom:
            return zoomIconNode
        }
    }

    func screenRect(in scn: ARSCNView) -> CGRect? {
        guard let tmp = self.imageBgNode.geometry as? SCNPlane else { return nil }
        
        //useful
        let w = Float(tmp.width/2)
        let h = Float(tmp.height/2)
        
        //get 3d rect locs
        let mid = self.imageNode.position
        let leftTopLoc = SCNVector3(mid.x - w, mid.y - h, mid.z)
        let rightBottomLoc = SCNVector3(mid.x + w, mid.y + h, mid.z)
        
        //get screen rect pts
        let leftTopPt = scn.convertToScreenPoint(loc: leftTopLoc, parent: self)
        let rightBottomPt = scn.convertToScreenPoint(loc: rightBottomLoc, parent: self)
        
        //check screen tap
        let fr = CGRect(x: leftTopPt.x, y: leftTopPt.y, width: rightBottomPt.x - leftTopPt.x, height: rightBottomPt.y - leftTopPt.y)
        return fr
    }
    
    func isTapOn(in scn: ARSCNView, pt: CGPoint) -> Bool {
        guard let fr = screenRect(in: scn) else { return false }
        return fr.contains(pt)
    }
    
    var zoomArtwork: Float {
        get {
            return imageNode.scale.x
        }
        set(val) {
            imageNode.scale = SCNVector3(x: val, y: val, z: val)
        }
    }
}
