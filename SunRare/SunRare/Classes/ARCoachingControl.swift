//
//  ARCoachingControl.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 03.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class ARCoachingControl: NSObject {
    private var guidanceOverlay: ARCoachingOverlayView?
    
    weak var sceneView: ARSCNView?
    
    var isActive: Bool {
        return guidanceOverlay?.isActive ?? false
    }
    
    private var configuredOnce = false
    private func config() {
        if configuredOnce { return }
        configuredOnce = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(appGoBg), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appGoLive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setOverlay(in sceneView: ARSCNView, automatically: Bool, forDetectionType goal: ARCoachingOverlayView.Goal, coachingDelegate: ARCoachingOverlayViewDelegate) {
        config()
        
        //save
        self.sceneView = sceneView

        //create
        let overlay = guidanceOverlay ?? ARCoachingOverlayView()
        overlay.session = sceneView.session
        overlay.delegate = coachingDelegate
        if overlay.superview != nil {
            overlay.removeFromSuperview()
        }
        sceneView.addSubview(overlay)
        guidanceOverlay = overlay
            
        //Set It To Fill Our View
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item:  overlay, attribute: .top, relatedBy: .equal, toItem: sceneView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item:  overlay, attribute: .bottom, relatedBy: .equal, toItem: sceneView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item:  overlay, attribute: .leading, relatedBy: .equal, toItem: sceneView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item:  overlay, attribute: .trailing, relatedBy: .equal, toItem: sceneView, attribute: .trailing, multiplier: 1, constant: 0)
        ])

        overlay.translatesAutoresizingMaskIntoConstraints = false

        //Enable The Overlay To Activate Automatically Based On User Preference
        overlay.activatesAutomatically = automatically
        
        //Set The Purpose Of The Overlay Based On The User Preference
        overlay.goal = goal
        
        //fix launch issue
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak overlay] in
            guard let tmp = overlay else { return }
            if !tmp.isActive {
                tmp.setActive(true, animated: true)
            }
        }
    }
    
    func hideCoaching() {
        guidanceOverlay?.setActive(false, animated: true)
    }
}

extension ARCoachingControl {
    @objc func appGoBg() {
        sceneView?.pause(nil)
    }
    @objc func appGoLive() {
        sceneView?.play(nil)
        
        if let tmp = guidanceOverlay, !tmp.isActive {
            tmp.setActive(true, animated: true)
        }
    }
}
