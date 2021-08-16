//
//  ArtworkMap.swift
//  ARWallArtwork
//
//  Created by Alen Korbut on 09.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import ARKit
import Hydra

/**
 Artwork Map provide easy way to load and save ARWorldMap from / to URL by using Promises
 
 @discussion could be used if ARWallArtwork supported with some custom UI and ARWallArtworkControl integrated directly instead of use Default AR Camera Screen (it already supported ArtworkMap)
 */
public class ArtworkMap { }

public extension ArtworkMap {
    /**
     Save active world map from session. If file exist under URL then it will be removed before save.
     
     @discussion -
     @param session exist session that would be used for get current world map
     @param url where to save url. Local file url
     @result Promise with success Void result or fail with some Error
     */
    static func save(session: ARSession, url: URL) -> Promise<Void> {
        return Promise { [weak session] res, rej, status in
            session?.getCurrentWorldMap { map, error in
                if let tmp = map {
                    do {
                        try? FileManager.default.removeItem(at: url)
                        try ArtworkMap.writeWorldMap(tmp, to: url)
                        res(())
                    }
                    catch let e {
                        rej(e)
                    }
                }
                else if let e = error {
                    rej(e)
                }
                else {
                    rej(MapError.nothingToSave)
                }
            }
        }
    }
    
    /**
     Load World Map from URL (local or remote)
     
     @discussion -
     @param url source url to load from
     @result Promise with success ARWorldMap or fail with some error
     */
    static func load(url: URL) -> Promise<ARWorldMap> {
        return Promise { res, rej, status in
            do {
                let map = try ArtworkMap.loadWorldMap(from: url)
                res(map)
            }
            catch let e {
                rej(e)
            }
        }
    }
}

private extension ArtworkMap {
    static func writeWorldMap(_ worldMap: ARWorldMap, to url: URL) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        try data.write(to: url, options: [.atomic])
    }
    static func loadWorldMap(from url: URL) throws -> ARWorldMap {
        let mapData = try Data(contentsOf: url)
        guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
            else { throw ARError(.invalidWorldMap) }
        return worldMap
    }
}
