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
     Artwork Content Type that showed inside artwork
     
     @discussion -
     */
    public enum ContentType: String, Codable {
        case img
        case gif
        case mp4
    }
    
    /**
     Content Link that load content async inside AR Artwork Node
     
     @discussion -
     */
    public var contentLink: String
    
    /**
     Artwork Content Type that showed by link
     
     @discussion -
     */
    public var contentType: ContentType
    
    /**
     Content Size in pixels used for show aspect ration in AR Artwork Node image subnode
     
     @discussion -
     */
    public var contentSize: CGSize
    
    /**
     Artwork Name
     
     @discussion -
     */
    public var artworkName: String
    
    /**
     Artist Name
     
     @discussion -
     */
    public var artistName: String
    
    /**
     Owner Name
     
     @discussion -
     */
    public var ownerName: String
    
    /**
     NFT Link
     
     @discussion -
     */
    public var nftLink: String
    
    public init(contentLink: String, contentType: ContentType, contentSize: CGSize, artworkName: String, artistName: String, ownerName: String, nftLink: String) {
        self.contentLink = contentLink
        self.contentType = contentType
        self.contentSize = contentSize
        self.artworkName = artworkName
        self.artistName = artistName
        self.ownerName = ownerName
        self.nftLink = nftLink
    }
}

extension ArtworkModel: Equatable {
    static public func ==(left: ArtworkModel, right: ArtworkModel) -> Bool {
        return left.contentLink == right.contentLink
    }
    static public func !=(left: ArtworkModel, right: ArtworkModel) -> Bool {
        return !(left == right)
    }
}
