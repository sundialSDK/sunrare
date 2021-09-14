//
//  ARCameraScreen.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 03.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit

public class ARCameraScreen: UIViewController {
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var placeNewButton: UIButton!
    @IBOutlet weak var addNodeButtonContainer: UIView!
    @IBOutlet weak var removeNodeButtonContainer: UIView!
    @IBOutlet weak var takeScreenshotContainer: UIView!
    @IBOutlet weak var infoContainer: UIView!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var zoomButton: UIButton!
    
    @IBOutlet weak var raribleIconButton: UIButton!
    @IBOutlet weak var reorderIconButton: UIButton!
    @IBOutlet weak var placementIcon: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    @IBOutlet weak var sysInfoLabel: UILabel!
    
    private var zoomMoving: CGFloat?
    private var worldMapSaveURL: URL?
    private weak var datasource: ARWallArtworkCameraDataSource?
        
    private lazy var wallArtwork: ARWallArtworkControl = {
        let tmp = ARWallArtworkControl()
        tmp.delegate = self
        tmp.overlayProvider = self
        return tmp
    }()
    
    var goBackAction: (()->())? = nil
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        //config
        sceneView.scene = SCNScene()
//        sceneView.showsStatistics = true
//        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.session.run(ARWorldTrackingConfiguration(), options: [.removeExistingAnchors, .resetTracking])
    }
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? SnapshotScreen,
           let tmp = sender as? SnapshotScreen.Model {
            vc.model = tmp
        }
    }
    
    deinit {
        wallArtwork.unbind()
    }
}

extension ARCameraScreen {
    func config(configuration: DefaultARCameraConfiguration, datasource: ARWallArtworkCameraDataSource?, completion: ((Error?)->Void)? = nil) {
        //make sure ui loaded
        loadViewIfNeeded()
        
        //store props
        self.datasource = datasource
        self.worldMapSaveURL = configuration.worldMapSaveURL
        
        //config UI based on config
        self.saveButton.isHidden = worldMapSaveURL == nil
        self.placeNewButton.isHidden = datasource == nil
        
        //reusable completion
        let defaultConfig: (ARWorldMap?)->() = { [weak self] map in
            do {
                try self?.bindWallControl(map: map)
                completion?(nil)
            }
            catch let e {
                completion?(e)
            }
        }
        
        //get initial map url
        guard let url = configuration.worldMapLoadURL else {
            defaultConfig(nil)
            return
        }
        
        //load initial map
        ArtworkMap.load(url: url) { [weak self] error, map in
            defaultConfig(map)
            self?.initialWorldMapDidLoad(succ: error == nil, url: url)
        }
    }
}

private extension ARCameraScreen {
    func showSysInfo(_ txt: String, succ: Bool) {
        //show load scene status
        sysInfoLabel.textColor = succ ? UIColor.green : UIColor.red
        sysInfoLabel.text = txt
        sysInfoLabel.isHidden = false
        
        //hide after some delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.sysInfoLabel.isHidden = true
        }
    }
    func bindWallControl(map: ARWorldMap?) throws {
        var wallConfig = ARWallArtworkControl.Configuration()
        wallConfig.initialWorldMap = map
        wallConfig.overlaySubNodes = Set([.arrow,.reorder,.link,.zoom])
        if let img = UIImage.placeholderArtwork() {
            wallConfig.artworkSubNodesContentInfo = [.artworkPlaceholder: img]
        }
        try wallArtwork.bindToARScene(sceneView, config: wallConfig)
    }
    func initialWorldMapDidLoad(succ: Bool, url: URL) {
        //show load scene status
        let txt = "World Map [\(url.lastPathComponent)]" + (succ ? " loaded succesfully" : " load failed")
        showSysInfo(txt, succ: succ)
    }
}

extension ARCameraScreen {
    @IBAction func pressedBack() {
        if let action = goBackAction {
            action()
        }
        else {
            if let vc = navigationController, vc.viewControllers.first != self {
                vc.popViewController(animated: true)
                return
            }
            dismiss(animated: true, completion: nil)
        }
    }
    @IBAction func unwindFromSnapshot(segue: UIStoryboardSegue) {
        //skip
    }
    @IBAction func pressedAddNode() {
        wallArtwork.addActiveNode()
    }
    @IBAction func pressedRemoveNode() {
        wallArtwork.removeActiveNode()
    }
    @IBAction func pressedScreenshot() {
        guard let tmp = wallArtwork.snapshot() else { return }
        let model = SnapshotScreen.Model(image: tmp.image, model: tmp.model)
        self.performSegue(withIdentifier: "showSnapshot", sender: model)
    }
    @IBAction func pressedPlaceNew() {
        datasource?.arWallArtworkFetchArtworkModel(in: self, completion: { [weak self] tmpModel in
            guard let tmp = tmpModel else { return }
            
            self?.wallArtwork.placeNewArtwork(model: tmp)
        })
    }
    
    @IBAction func pressedRarible() {
        wallArtwork.openSelectedArtworkNFTLink()
    }
    @IBAction func pressedReorder() {
        wallArtwork.reorderSelectedArtwork()
    }
    
    @IBAction func draggingZoom(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            //min / max loc for move
            let minY = placementIcon.frame.midY
            let maxY = raribleIconButton.frame.midY
            let dist = maxY - minY
            let half = dist/2

            //get zoom
            let move = min(half, max(-half, gesture.translation(in: nil).y))
            let perc = (move + half)/dist
        
            //update zoom button
            zoomMoving = move
            
            //update zoom value
            let ttl = Int(perc * 100)
            zoomButton.setTitle("\(ttl)%", for: .normal)
            
            //zoom artwork
            wallArtwork.zoomSelectedArtwork(perc: Float( perc ))
        default:
            zoomMoving = nil
        }
    }
    
    @IBAction func pressedSave() {
        guard let url = worldMapSaveURL else { return }
        
        wallArtwork.saveScene(url: url) { [weak self] error in
            let succ = error == nil
            let txt = succ ? "Saved Successfully" : "Save Failed"
            self?.showSysInfo(txt, succ: succ)
        }
    }
}


extension ARCameraScreen: ARWallArtworkControlDelegate {
    public func arWallArtworkControl(_ control: ARWallArtworkControl, showCoaching: Bool) {
        //show / hide all controls while show coaching
        let list = [placeNewButton, placementIcon, raribleIconButton, reorderIconButton, addNodeButtonContainer, removeNodeButtonContainer, takeScreenshotContainer, infoContainer, zoomButton, saveButton]
        list.forEach { tmp in
            tmp?.isUserInteractionEnabled = !showCoaching
            tmp?.alpha = showCoaching ? 0.0 : 1.0
        }
    }
    public func arWallArtworkControl(_ control: ARWallArtworkControl, didSelectArtwork model: ArtworkModel, placing: Bool, zoom: Float) {
        
        //fill names
        titleLabel.text = model.artworkName
        artistLabel.text = model.artistName

        //show ui
        infoContainer.isHidden = false
        placementIcon.isHidden = false
        
        //placing depended ui
        raribleIconButton.isHidden = placing
        reorderIconButton.isHidden = placing
        zoomButton.isHidden = placing
        addNodeButtonContainer.isHidden = !placing
        removeNodeButtonContainer.isHidden = !placing
        takeScreenshotContainer.isHidden = placing
        
        //update zoom
        let ttl = Int(zoom * 100)
        zoomButton.setTitle("\(ttl)%", for: .normal)
    }
    
    public func arWallArtworkControlDidUnselectArtwork(_ control: ARWallArtworkControl) {
        //title
        infoContainer.isHidden = true
        
        //overlay
        placementIcon.isHidden = true
        raribleIconButton.isHidden = true
        reorderIconButton.isHidden = true
        zoomButton.isHidden = true
        
        //button
        addNodeButtonContainer.isHidden = true
        removeNodeButtonContainer.isHidden = true
        
        //show only screenshot button
        takeScreenshotContainer.isHidden = false
    }
}

extension ARCameraScreen: ARWallArtworkControlOverlayProvider {
    public func arWallArtworkControl(_ control: ARWallArtworkControl, updateOverlayFor model: ArtworkModel, info: [ArtworkSubNodeType : CGPoint]) {
        //reusable
        let setTr: (UIView, CGPoint)->() = { tmp, pt in
            tmp.transform = CGAffineTransform.identity
            let fix = tmp.frame
            tmp.transform = CGAffineTransform(translationX: pt.x - fix.midX, y: pt.y - fix.midY)
        }
        
        for tmp in info {
            switch tmp.key {
                case .artworkPlaceholder:
                    //not supported
                    break
                case .zoom:
                    setTr(zoomButton, tmp.value)
                    
                    //move up / down
                    if let tmp = zoomMoving {
                        zoomButton.transform = zoomButton.transform.translatedBy(x: 0, y: tmp)
                    }
                                            
                case .arrow:
                    setTr(infoContainer, CGPoint(x: tmp.value.x, y: tmp.value.y - infoContainer.bounds.height))
                    setTr(placementIcon, tmp.value)
                case .link:
                    setTr(raribleIconButton, tmp.value)
                case .reorder:
                    setTr(reorderIconButton, tmp.value)
            }
        }
    }
}
