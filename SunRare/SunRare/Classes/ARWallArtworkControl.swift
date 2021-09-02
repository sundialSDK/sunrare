//
//  ARWallArtworkControl.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 03.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import ARKit
import SceneKit

/**
 ARWallArtworkControl is general control for support wall detection and manage artworks
 
 @discussion typically default AR Camera Screen should be enough for show general functionality, but if need to customize UI then need to support ARWallArtworkControl directly with delegate and overlay provider (like already done in default AR Camera Screen)
 */
public class ARWallArtworkControl: NSObject {
    /**
     ARWallArtworkControl Delegate provide event callback
     
     @discussion -
     */
    public weak var delegate: ARWallArtworkControlDelegate?
    
    /**
     ARWallArtworkControl Overlay Provider give ability to customize 2D overlay over 3D subnodes coords
     
     @discussion -
     */
    public weak var overlayProvider: ARWallArtworkControlOverlayProvider?

    private weak var sceneView: ARSCNView?
    
    private var tapGesture: UITapGestureRecognizer?
    private var coachingControl = ARCoachingControl()
    private var configuration = Configuration()
    private var overlayBounds: CGRect = .zero
    private var placingNode: ArtworkNode?
    private var selectedNode: ArtworkNode?
    
    private var isZooming = false
        
    private var artworkNodes: [ArtworkNode] {
        return sceneView?.scene.rootNode.childNodes.compactMap({ $0 as? ArtworkNode }) ?? []
    }
    
    public override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(screenRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}

private extension ARWallArtworkControl {
    @objc func screenRotated() {
        DispatchQueue.main.async { [weak self] in
            guard let tmp = self?.sceneView?.bounds else { return }
            self?.overlayBounds = tmp
        }
    }
    @objc func didTap(gesture: UITapGestureRecognizer) {
        guard let scn = sceneView else { return }
        
        //placing some node, so skip tap to select
        if placingNode != nil { return }
        
        //check tap on node
        let pt = gesture.location(in: sceneView)
        guard let node = artworkNodes.first(where: { $0.isTapOn(in: scn, pt: pt) }) else {
            selectNode(nil)
            return
        }

        //select tapped node
        selectNode(node)
    }
        
    func selectNode(_ node: ArtworkNode?) {
        guard selectedNode != node else { return }
        
        //select
        let isPlacing = placingNode == node
        selectedNode?.state = .none
        node?.state = isPlacing ? .placing : .selected
        selectedNode = node
        
        //notify
        if let tmp = node {
            delegate?.arWallArtworkControl(self, didSelectArtwork: tmp.model, placing: isPlacing, zoom: tmp.zoomArtwork)
        }
        else {
            delegate?.arWallArtworkControlDidUnselectArtwork(self)
        }
    }
    
    func updateOverlay() {
        guard let scn = sceneView, let node = placingNode ?? selectedNode else { return }
        
        //fill overlay points for each node
        var overlayInfo: [ArtworkSubNodeType: CGPoint] = [:]
        for tmp in configuration.overlaySubNodes {
            overlayInfo[tmp] = scn.convertToScreenPoint(loc: node.subNode(by: tmp).position, parent: node)
        }
        
        //notify
        DispatchQueue.main.async { [weak self] in
            if let tmp = self {
                tmp.overlayProvider?.arWallArtworkControl(tmp, updateOverlayFor: node.model, info: overlayInfo)
            }
        }
    }
}

public extension ARWallArtworkControl {
    /**
     General Bind to AR Screne method.
     
     @discussion throw BindError.alreadyBind or GeneralError.a12Required in some cases
     @param sceneView where need to bind
     @param config see details in ARWallArtworkControl.Configuration
     */
    func bindToARScene(_ sceneView: ARSCNView, config: Configuration = Configuration()) throws {
        //already bind
        if self.sceneView != nil {
            throw BindError.alreadyBind
        }
        
        //a12 chip required
        if !ARWallArtworkControl.isDeviceSupported() {
            throw GeneralError.a12Required
        }
        
        //save
        self.sceneView = sceneView
        self.overlayBounds = sceneView.bounds
        
        //update config
        self.configuration = config
        
        //required to handle each captured frame
        sceneView.delegate = self
        
        //vertical plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.initialWorldMap = config.initialWorldMap
        configuration.planeDetection = [.vertical]
        
        //try to set builtin ultra wide camera
        if #available(iOS 14.5, *) {
            if let videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: { $0.captureDeviceType == .builtInUltraWideCamera }) {
                configuration.videoFormat = videoFormat
            }
        }
        
        //config lidar if needed
        if #available(iOS 13.4, *) {
            configuration.sceneReconstruction = .init(rawValue: 0)
        } else {
            // Fallback on earlier versions
        }
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        //coaching
        coachingControl.setOverlay(in: sceneView, automatically: self.configuration.automaticallyCoaching, forDetectionType: .verticalPlane, coachingDelegate: self)
        
        //tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        sceneView.addGestureRecognizer(tap)
        self.tapGesture = tap
    }
    
    /**
     Unbind from some ARSCNView
     
     @discussion nothing happens if wasn't bind to anywhere
     */
    func unbind() {
        //remove gesture
        if let tap = self.tapGesture {
            sceneView?.removeGestureRecognizer(tap)
            self.tapGesture = nil
        }
        
        //reset scene
        sceneView?.delegate = nil
        sceneView = nil
        
        //reset active node
        placingNode?.removeFromParentNode()
        placingNode = nil
    }
    
    /**
     Convert active AR Artwork Node to AR Anchor and store it inside scene (+ could be saved)
     
     @discussion nothing happens if no placing node
     */
    func addActiveNode() {
        guard let node = placingNode else { return }

        //create anchor
        let anchor = ArtworkAnchor(transform: node.simdTransform, model: node.model)
        sceneView?.session.add(anchor: anchor)
        node.removeFromParentNode()
        
        //unselect
        selectNode(nil)
        placingNode = nil
    }
    
    /**
     Remove active placing node (initial place or reorder)
     
     @discussion nothing happens if no placing node
     */
    func removeActiveNode() {
        guard placingNode != nil else { return }

        placingNode?.removeFromParentNode()

        //unselect
        selectNode(nil)
        placingNode = nil
    }
    
    /**
     Create and track active node with location in center of screen (2D -> 3D)
     
     @discussion if coaching active then node would be added after coaching dismiss, otherwise - immediately
     @param model ArtworkModel that would be used in addition with ARWallArtworkControl.Configuration.artworkSubNodesContentInfo to create AR Artwork Node
     */
    func placeNewArtwork(model: ArtworkModel) {
        //remove old one
        placingNode?.removeFromParentNode()
        
        //add new one
        let node = ArtworkNode(model: model, contentInfo: configuration.artworkSubNodesContentInfo)
        placingNode = node
        selectNode(node)
        
        //add immediately if coaching inactive
        if !coachingControl.isActive {
            sceneView?.scene.rootNode.addChildNode(node)
        }
    }
    
    /**
     Search node with artwork model, remove AR Anchor and placeNewArtwork (see doc inside it) with grabbed artwork model
     
     @discussion nothing happens if can't find artwork node with exact artwork model
     @param model ArtworkModel that would be used for search exist node
     @result True if node start reording succesfully, False if node not found in child nodes
     */
    @discardableResult func reorderArtwork(model: ArtworkModel) -> Bool {
        //search node
        guard let node = artworkNodes.first(where: { $0.model == model }) else { return false }
        
        //unselect
        selectNode(nil)
        
        //remove anchor and plce node again
        if let anchor = sceneView?.anchor(for: node) {
            sceneView?.session.remove(anchor: anchor)
            
            placeNewArtwork(model: model)
            placingNode?.simdTransform = anchor.transform
        }
        else {
            placingNode = node
            selectNode(node)
        }
        
        return true
    }
    
    /**
     If selected some node or exist just single artwork node then it cropped with some inset and snapshot made for exact node, otherwise whole scene used
     
     @discussion -
     @result nil if sceneView doesn't exist, otherwise image and model tuple + in case of crop some exact node model would be provided as well
     */
    func snapshot() -> (image: UIImage, model: ArtworkModel?)? {
        guard let scn = sceneView else { return nil }
        
        //reusable
        let crop: (UIImage, CGRect?) -> (UIImage) = { img, fr in
            guard let tmpFr = fr else { return img }
            return img.crop(rect: tmpFr.insetBy(dx: -100, dy: -100), scale: UIScreen.main.scale) ?? img
        }

        //already selected something or just one item exist
        if let tmp = selectedNode ?? (artworkNodes.count == 1 ? artworkNodes.first : nil) {
            return (image: crop(scn.snapshot(), tmp.screenRect(in: scn)), model: tmp.model)
        }
        
        //whole scene
        return (image: scn.snapshot(), model: nil)
    }
    
    /**
     Zoom selected node to exact percent value
     
     @discussion nothing happens if no selected node.
     @param perc zoom value in 0-1 format
     @result True if selected node zoomed succesfully, otherwise False
     */
    @discardableResult func zoomSelectedArtwork(perc: Float) -> Bool {
        guard let node = selectedNode else { return false }
        
        node.zoomArtwork = perc
        (sceneView?.anchor(for: node) as? ArtworkAnchor)?.zoom = perc
        
        return true
    }
    
    /**
     Save scene world map into some file url.
     
     @discussion throw MapError.sessionRequired if sceneView == nil. NOTE: active placing node wouldn't be saved - it's need to be stored first!
     @param url destination file url to save in
     @param completion success with nil error result or fail with some error
     @result Promise with
     */
    func saveScene(url: URL, completion: ((Error?)->())? = nil) {
        guard let session = sceneView?.session else {
            completion?(MapError.sessionRequired)
            return
        }
        ArtworkMap.save(session: session, url: url, completion: completion)
    }
    
    /**
     Open selected artwork nft link in safari
     
     @discussion useful in case if need to call nft link action for selected node
     @result True if ntf link opened succesfully, otherwise False
     */
    @discardableResult func openSelectedArtworkNFTLink() -> Bool {
        guard let link = selectedNode?.model.nftLink,
              let url = URL(string: link)
        else { return false }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return true
    }
    
    /**
     Reorder selected artwork
     
     @discussion useful in case if need to call reorder action for selected node
     @result True if node start reording succesfully, False if node not found in child nodes
     */
    @discardableResult func reorderSelectedArtwork() -> Bool {
        guard let model = selectedNode?.model else { return false }
        return self.reorderArtwork(model: model)
    }
}

extension ARWallArtworkControl: ARSCNViewDelegate {
    public func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        //create artwork node for artwork anchor
        if let tmp = anchor as? ArtworkAnchor {
            let res = ArtworkNode(model: tmp.model, contentInfo: configuration.artworkSubNodesContentInfo)
            res.zoomArtwork = tmp.zoom
            return res
        }
        //create some default node for plane and other anchors
        return SCNNode()
    }
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //hide coaching if start detect something
        if !configuration.automaticallyCoaching && coachingControl.isActive {
            coachingControl.hideCoaching()
        }
        
        // Cast ARAnchor as ARPlaneAnchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        guard let planeGeometry = ARSCNPlaneGeometry(device: device) else { return }

        planeGeometry.update(from: planeAnchor.geometry)

        //get color from config
        guard let color = configuration.visualizeDetectedPlane else { return }
        
        // Add material to geometry
        let material = SCNMaterial()
        material.diffuse.contents = color
        planeGeometry.materials = [material]

        // Create a SCNNode from geometry
        let planeNode = SCNNode(geometry: planeGeometry)

        // Add the newly created plane node as a child of the node created for the ARAnchor
        node.addChildNode(planeNode)
    }

    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Cast ARAnchor as ARPlaneAnchor, get the child node of the anchor, and cast that node's geometry as an ARSCNPlaneGeometry
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let planeGeometry = planeNode.geometry as? ARSCNPlaneGeometry
            else { return }
        
        planeGeometry.update(from: planeAnchor.geometry)
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        //skip while zooming
        if isZooming { return }
        
        updateOverlay()
        
        //search 3d loc
        let midPt = CGPoint(x: overlayBounds.width/2, y: overlayBounds.height/2)
        guard let result = sceneView?.raycastResult(from: midPt, allowing: configuration.allowingRaycastTarget).last else { return }
        
        //move active node
        placingNode?.position = SCNVector3.position(from: result.worldTransform)
        placingNode?.simdOrientation = simd_quatf(result.worldTransform)
        placingNode?.eulerAngles.x = .pi
        placingNode?.position.z += 0.01
    }
}

extension ARWallArtworkControl: ARCoachingOverlayViewDelegate {
    public func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        delegate?.arWallArtworkControl(self, showCoaching: true)
        
        //hide active add node while coaching
        placingNode?.removeFromParentNode()
    }
    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        delegate?.arWallArtworkControl(self, showCoaching: false)
        
        //add active node after coaching
        if let node = placingNode, node.parent == nil {
            sceneView?.scene.rootNode.addChildNode(node)
        }
    }
}
