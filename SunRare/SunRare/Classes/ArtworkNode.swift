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
import AVFoundation

class ArtworkNode: SCNNode {
    private(set) var model: ArtworkModel
    private(set) var arrowNode: SCNNode
    private(set) var imageBgNode: SCNNode
    private(set) var imageNode: SCNNode
    private(set) var reorderIconNode: SCNNode
    private(set) var linkIconNode: SCNNode
    private(set) var zoomIconNode: SCNNode
    
    private var cachedImgView: UIImageView?
    private var cachedPlayer: AVPlayer?
    
    var state: ArtworkState = .none {
        didSet {
            updateByState()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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


extension ArtworkNode {
    private func loadImage(url: URL) {
        let tmpModel = model
        
        //load content in bg
        DispatchQueue.global().async {
            //get cached data
            let cached = ARWallArtworkControl.cacheProvider?.getCachedImageContent(model: tmpModel)

            //get content
            guard let data = cached ?? (try? Data(contentsOf: url)),
                  let img = UIImage(data: data)?.cgImage
            else { return }
            
            //cache newly loaded data
            if cached == nil {
                ARWallArtworkControl.cacheProvider?.cache(model: tmpModel, imageContent: data)
            }
            
            //fill content
            DispatchQueue.main.async { [weak self] in
                self?.imageNode.geometry?.materials.first?.diffuse.contents = img
            }
        }
    }
    private func loadGIF(url: URL) {
        let tmpModel = model
        let sz = model.contentSize
        
        //load content in bg
        DispatchQueue.global().async {
            //get cached data
            let cached = ARWallArtworkControl.cacheProvider?.getCachedImageContent(model: tmpModel)

            //get content
            guard let data = try? Data(contentsOf: url),
                  let img = UIImage.gif(data: data)
            else { return }
            
            //cache newly loaded data
            if cached == nil {
                ARWallArtworkControl.cacheProvider?.cache(model: tmpModel, imageContent: data)
            }
            
            //fill content
            DispatchQueue.main.async { [weak self] in
                //use image view to handle correctly animations
                let tmp = UIImageView(frame: CGRect(origin: .zero, size: sz))
                tmp.image = img
                self?.cachedImgView = tmp

                //use image view layer as contents
                self?.imageNode.geometry?.materials.first?.diffuse.contents = tmp.layer
            }
        }
    }
    private func loadMP4(url: URL) {
        //cache
        let cachedURL = ARWallArtworkControl.cacheProvider?.getCachedVideoURL(model: model)
        if cachedURL == nil {
            ARWallArtworkControl.cacheProvider?.cache(model: model, videoURL: url)
        }
        
        //screen size with aspect ratio on content size
        let max = max(model.contentSize.width, model.contentSize.height)
        let realSize = CGSize(width: model.contentSize.width/max, height: model.contentSize.height/max)
        let sz = CGSize(width: UIScreen.main.bounds.width * realSize.width, height: UIScreen.main.bounds.height * realSize.height)
                
        //video
        let player = AVPlayer(url: cachedURL ?? url)
                
        // A SpriteKit scene to contain the SpriteKit video node
        let spriteKitScene = SKScene(size: sz)
        spriteKitScene.scaleMode = .aspectFit
        
        // To make the video loop
        player.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: player.currentItem)

        // Create the SpriteKit video node, containing the video player
        let videoSpriteKitNode = SKVideoNode(avPlayer: player)
        videoSpriteKitNode.position = CGPoint(x: spriteKitScene.size.width / 2.0, y: spriteKitScene.size.height / 2.0)
        videoSpriteKitNode.size = spriteKitScene.size
        videoSpriteKitNode.yScale = -1.0
        videoSpriteKitNode.play()
        spriteKitScene.addChild(videoSpriteKitNode)
                
        imageNode.geometry?.materials.first?.diffuse.contents = spriteKitScene
        
        self.cachedPlayer = player
    }
    private func loadContent(url: URL?) {
        guard let tmp = url else { return }
        
        switch model.contentType {
        case .img:
            loadImage(url: tmp)
        case .gif:
            loadGIF(url: tmp)
        case .mp4:
            loadMP4(url: tmp)
        }
    }
    
    // This callback will restart the video when it has reach its end
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
}
