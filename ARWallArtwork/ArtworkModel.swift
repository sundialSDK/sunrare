//
//  ArtworkModel.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 09.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import UIKit

/**
 Artwork Model is general model for AR Artwork Node.
 
 @discussion -
 */
public struct ArtworkModel: Codable {
    /**
     Image Link that load image async inside AR Artwork Node
     
     @discussion -
     */
    public var imageLink: String
    
    /**
     Image Size in pixels used for show aspect ration in AR Artwork Node image subnode
     
     @discussion -
     */
    public var imageSize: CGSize
    
    /**
     Image / Artwork Name
     
     @discussion -
     */
    public var imageName: String
    
    /**
     Artist Name
     
     @discussion -
     */
    public var artistName: String
    
    /**
     Link
     
     @discussion -
     */
    public var link: String
    
    public init(imageLink: String, imageSize: CGSize, imageName: String, artistName: String, link: String) {
        self.imageLink = imageLink
        self.imageSize = imageSize
        self.imageName = imageName
        self.artistName = artistName
        self.link = link
    }
}

extension ArtworkModel: Equatable {
    static public func ==(left: ArtworkModel, right: ArtworkModel) -> Bool {
        return left.imageLink == right.imageLink
    }
    static public func !=(left: ArtworkModel, right: ArtworkModel) -> Bool {
        return !(left == right)
    }
}
