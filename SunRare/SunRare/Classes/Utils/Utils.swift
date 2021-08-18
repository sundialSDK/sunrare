//
//  Utils.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 03.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import DeviceKit

/**
 Default Camera Data Source provide ability to fetch artwork and present some gallery over camera if needed.
 
 @discussion if not set to default camera then [+] would be hidden
 */
public protocol ARWallArtworkCameraDataSource: AnyObject {
    /**
     Fetch artwork model
     
     @discussion Default Camera [+] button call this action to fetch some new ArtworkModel that would be placed on some real world wall
     @param vc Default Camera view controller that could be used for show some gallery screen for pick artworks
     @param completion Result artwork (or nil if canceled) that picked from some gallery
     */
    func arWallArtworkFetchArtworkModel(in vc: UIViewController, completion: @escaping (ArtworkModel?)->())
}

/**
 Notify feedback about some events in ARWallArtworkControl
 
 @discussion Should be supported by some View Controller that use ARWallArtworkControl (like Default Camera already did)
 */
public protocol ARWallArtworkControlDelegate: AnyObject {
    /**
     Handle Coaching changes display state
     
     @discussion called on coaching show / hide state
     @param control ARWallArtworkControl that bind to delegate
     @param showCoaching Current show state for coaching
     */
    func arWallArtworkControl(_ control: ARWallArtworkControl, showCoaching: Bool)
    
    /**
     Handle Exact Artwork selection
     
     @discussion called on artwork node selection
     @param control ARWallArtworkControl that bind to delegate
     @param model model grabbed from AR Node
     @param placing true if node is in initial placing (or reorder) mode, otherwise false
     @param zoom current zoom value for artwork node
     */
    func arWallArtworkControl(_ control: ARWallArtworkControl, didSelectArtwork model: ArtworkModel, placing: Bool, zoom: Float)
    
    /**
     Handle Artwork Unselection
     
     @discussion called on unselect some already selected artwork node
     @param control ARWallArtworkControl that bind to delegate
     */
    func arWallArtworkControlDidUnselectArtwork(_ control: ARWallArtworkControl)
}

/**
 Overlay provider used for place 2D content on screen based on some AR node subnodes info
 
 @discussion should be used only for change 2D coordinates for some overlay controls, but for show / hide state should be used delegate callbacks
 */
public protocol ARWallArtworkControlOverlayProvider: AnyObject {
    /**
     Update Overlay action for some specific AR artwork node subnodes
     
     @discussion called on Main / UI Queue each time in renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) with already converted 2D coords from 3D coords
     @param control ARWallArtworkControl that bind to overlay provider
     @param model active placing or simply selected AR node model
     @param info AR node subnodes 2D coordinates. NOTE: subnodes grabbed from ARWallArtworkControl.configuration.overlaySubNodes, so if you're not set some subnode there then it wouldn't appear here.
     */
    func arWallArtworkControl(_ control: ARWallArtworkControl, updateOverlayFor model: ArtworkModel, info: [ArtworkSubNodeType: CGPoint])
}

internal enum ArtworkState {
    case none
    case placing
    case selected
}

/**
 All configurable subnodes for AR Artwork node
 
 @discussion only configurable subnodes, but not all!
 */
public enum ArtworkSubNodeType {
    /**
     Artwork Placeholder could be used for set some placeholder that would be displayed while real image loading
     
     @discussion -
     */
    case artworkPlaceholder
    
    /**
     Link node that typically displayed in left bottom corner
     
     @discussion -
     */
    case link
    
    /**
     Reorder node that typically displayed in right bottom corner
     
     @discussion -
     */
    case reorder
    
    /**
     Selection marker arrow node that typically displayed in top mid edge
     
     @discussion -
     */
    case arrow
    
    /**
     Current zoom value that typically displayed in right mid edge
     
     @discussion -
     */
    case zoom
}

public extension ARWallArtworkControl {
    
    /**
     ARWallArtworkControl Configuration. Default configuration allow only place new artworks with image node over detected plane geomery
     
     @discussion for extra ability for configuration see each param.
     */
    struct Configuration {
        /**
         Allowing raycast target. Typically default .existingPlaneGeometry value should be used in most of cases
        
         @discussion for some specific business logic or for debug purposes could be used different values
         */
        public var allowingRaycastTarget: ARRaycastQuery.Target = .existingPlaneGeometry
        
        /**
         Visualize detected plane. By default detected planes (vertical one - walls) are not visualized
        
         @discussion for debug purposes could be used for visualize detected planes
         */
        public var visualizeDetectedPlane: UIColor? = nil
        
        /**
         Provide AR artwork node subnodes that would be used for update overlay (3D -> 2D coords)
         
         @discussion used ARWallArtworkControlOverlayProvider updateOverlayFor callback
         */
        public var overlaySubNodes: Set<ArtworkSubNodeType> = Set([])
        
        /**
         Each subnode could be configured to show some content in AR (3D! NOT 2D) if needed. Also could be used to show artwork placeholder for show some image before load real one
         
         @discussion dy default all subnodes contain clear content and used as anchor for 2D overlay content
         */
        public var artworkSubNodesContentInfo: [ArtworkSubNodeType: Any] = [:]
        
        /**
         True - coaching will disppear when some real wall detected and (if some initial world map set) some saved artwork node detected. False - only some real wall detected. False is default value.
         
         @discussion if False set and some initialWorldMap set then saved artwork nodes could appear after some delay after scan old location
         */
        public var automaticallyCoaching: Bool = false
        
        /**
         Some saved artworks that would appear in ARSCView
         
         @discussion see automaticallyCoaching for extra detection logic
         */
        public var initialWorldMap: ARWorldMap? = nil
        
        public init() {}
    }
    
    /**
     Check if current device supported by ARWallArtwork framework
     
     @discussion A12+ chip device required
     @result True if device supported, otherwise False
     */
    static func isDeviceSupported() -> Bool {
        return Device.isA12Chip()
    }
    
    /**
     Request Camera access with completion result
     
     @discussion could be used for request camera access before present AR Camera screen
     @param completion authorized or no result
     */
    static func requestCameraAccess(completion: @escaping (Bool)->()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                completion(true)
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            default:
                completion(false)
        }
    }
    
    /**
     Present default AR Camera Screen with configuration and datasource over some view controller
     
     @discussion could be used for show some default AR Camera Screen, but if need to customize UI then need to support ARWallArtworkControl directly with delegate and overlay provider.
     @param configuration some configuration for default ar camera screen
     @param datasource bind to [+] button inside AR Camera Screen. If set then called by press or whole button hidden if datasource set nil
     @param in source view controller that used for present default AR Camera Screen
     */
    static func presentDefaultARCameraScreen(configuration: DefaultARCameraConfiguration, datasource: ARWallArtworkCameraDataSource?, in vc: UIViewController) throws {
        //a12 chip required
        if !self.isDeviceSupported() {
            throw GeneralError.a12Required
        }
        
        //instantiate camera
        guard let nav = UIStoryboard(name: "Main", bundle: Bundle.current).instantiateInitialViewController() as? UINavigationController,
              let camVc = nav.viewControllers.first as? ARCameraScreen
        else {
            throw GeneralError.defaultCameraFailed
        }
        
        //show
        vc.present(nav, animated: true, completion: nil)
        
        //config
        camVc.config(configuration: configuration, datasource: datasource)
    }
}


/**
 Default AR Camera Screen Configuration
 
 @discussion -
 */
public struct DefaultARCameraConfiguration {
    /**
     Initial World Map Load URL. Could be local file url or remote file URL as well
     
     @discussion -
     */
    public var worldMapLoadURL: URL? = nil
    
    /**
     World Map Local File Save URL. If some file already exist under this local file url then it would be removed before save (would be overwritten). If set to nil then save button hidden inside Default AR Camera Screen.
     
     @discussion -
     */
    public var worldMapSaveURL: URL? = nil
    
    public init() { }
}
