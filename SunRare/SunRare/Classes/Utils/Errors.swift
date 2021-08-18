//
//  Errors.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 09.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation

/**
 General Errors
 
 @discussion -
 */
public enum GeneralError: LocalizedError {
    /**
     A12+ Chip device required error
     
     @discussion -
     */
    case a12Required
    
    /**
     Default Camera instintiate failed error
     
     @discussion -
     */
    case defaultCameraFailed
    
    public var errorDescription: String? {
        switch self {
        case .a12Required:
            return NSLocalizedString("GeneralError.a12Required", comment: "A12(+) Chip device required")
        case .defaultCameraFailed:
            return NSLocalizedString("GeneralError.defaultCameraFailed", comment: "Can't instantiate default camera screen")
        }
    }
}

/**
 Artwork Map Errors
 
 @discussion -
 */
public enum MapError: LocalizedError {
    /**
     Nothing to Save error. ARWorldMap missed
     
     @discussion -
     */
    case nothingToSave
    
    /**
     Session Required Error. ARSCNView missed when get session on save action.
     
     @discussion -
     */
    case sessionRequired
    
    public var errorDescription: String? {
        switch self {
        case .nothingToSave:
            return NSLocalizedString("MapError.nothingToSave", comment: "Nothing to save. ARWorldMap missed")
        case .sessionRequired:
            return NSLocalizedString("MapError.sessionRequired", comment: "Session Required to grab and save ARWorldMap")
        }
    }
}

/**
 Bind Errors
 
 @discussion -
 */
public enum BindError: LocalizedError {
    /**
     ARWallArtworkControl Already bind, so need to unbind before call bind!
     
     @discussion -
     */
    case alreadyBind
        
    public var errorDescription: String? {
        switch self {
        case .alreadyBind:
            return NSLocalizedString("BindError.alreadyBind", comment: "Already bind to some scene. Need to unbind first")
        }
    }
}
