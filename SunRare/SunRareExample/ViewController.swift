//
//  ViewController.swift
//  SunRare
//
//  Created by Alen Korbut on 03.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import UIKit
import SunRare
import AVFoundation
import ARKit

class ViewController: UIViewController {
    @IBOutlet weak var checkCameraAccessBeforeSwitch: UISwitch!
    @IBOutlet weak var worldMapTextField: UITextField!
    
    //test all artworks
    let allArtworks = [ArtworkModel(contentLink: "https://helpx.adobe.com/content/dam/help/en/photoshop/using/convert-color-image-black-white/jcr_content/main-pars/before_and_after/image-before/Landscape-Color.jpg", contentType: .img, contentSize: CGSize(width: 1600, height: 664), artworkName: "Landscape", artistName: "Alen", ownerName: "Yahoo", nftLink: "https://www.google.com"),
                       
                       ArtworkModel(contentLink: "https://i.pinimg.com/736x/7e/1c/0b/7e1c0b3223789770299bc3b66b2fc2a0.jpg", contentType: .img, contentSize: CGSize(width: 607, height: 1080), artworkName: "Flower", artistName: "Sandra", ownerName: "Yahoo", nftLink: "https://www.rambler.ru"),
                       
                       ArtworkModel(contentLink: "https://interactive-examples.mdn.mozilla.net/media/cc0-images/grapefruit-slice-332-332.jpg", contentType: .img, contentSize: CGSize(width: 332, height: 332), artworkName: "Grapefruit", artistName: "Tubrok", ownerName: "Yahoo", nftLink: "https://www.yahoo.com"),
    
                       ArtworkModel(contentLink: "https://i.gifer.com/fxVE.gif", contentType: .gif, contentSize: CGSize(width: 540, height: 540), artworkName: "Animation", artistName: "GIFER", ownerName: "GIFER", nftLink: "https://i.gifer.com/fxVE.gif"),
    
                       ArtworkModel(contentLink: "https://video-weaver.lax03.hls.ttvnw.net/v1/playlist/CpwEkQfRnlbp-qzTzVNIDGiQ9KWPPd4XOVcdKGq6THh_9bVZs0nqjSEw8KfHtW8fEuZodV1vSQExE_IbvhAojkKEc_-WO4PX1kXx61-d9X3TYYfhUWzv-GBkmhZmqqQDAWmDx--hQf73QbP0KR4U-ttxYA0fFp3aXZ3oiwT3lXjoWygjCnIewMGai5gWRGZpy32jTWZpi5Nxe_LJWMB2Lzph0gClfmY9GnJxcyThvNegwVZuj2m13A0RG7EG-N4PWw0DlQLgSx0EuWU7FFQbhqF5Bq8Eghr9poh5MDaqeGsgCNNc-bmEfFVOHXvbgIb4wqrCQWPNo-435OkRW3yZ65w8JJwfXpR1mrI0Xz6INaP0Kd7d7pw1JQdGePz2ILGP6cwkVVxQsg-xdvEoyJgV-3sJvZ4SXuHBlimv4WRl3miaMn0whm50pW1jSYetcALd3FwKkDu3p3EFcZ1UfvCUbSK9jRYnwseeGbM3xRf12DxYb9_tOssPU6AKlhwmmT0xNNohEOMUH7TjFB_c9l80YL3LTNeJS_GgihyTMvcfRrTpS_j0aiOxWhbijWVnaMauGGnvBVWGmXGDYfCxuMzhElg8P855IQkvIgN2-LVranYUgO_X1yibSM7acWrZkHn3qCHswHynpEOkhSSb5cfhsUjjL4dQlWeVPIBoLmeUU4DR9ngGyjAPFPAc4AW5HqQuXEjvKhhL50J6wK2ikYVkEhC3cxog6bLP496hOzln2pDHGgzHb9bF7OZjg0E1ijY.m3u8", contentType: .mp4, contentSize: CGSize(width: 1920, height: 1080), artworkName: "LOL", artistName: "zxcursed", ownerName: "zxcursed", nftLink: "https://www.twitch.tv/zxcursed")]
    var newItmIdx = 0
    
    func showAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showCamera() {
        //map
        let mapText = worldMapTextField.text ?? ""
        let mapURL: URL? = mapText.isEmpty ? nil : (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false))?.appendingPathComponent(mapText)
        
        //show ui
        var config = DefaultARCameraConfiguration()
        config.worldMapLoadURL = mapURL
        config.worldMapSaveURL = mapURL
        
        do {
            try ARWallArtworkControl.presentDefaultARCameraScreen(configuration: config, datasource: self, in: self)
        }
        catch let e {
            let alert = UIAlertController(title: "Error", message: e.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
}


extension ViewController {
    @IBAction func pressedOpenARWallArtwork() {
        //provide different logic for camera access
        if checkCameraAccessBeforeSwitch.isOn {
            //ask camera access and show ui
            ARWallArtworkControl.requestCameraAccess { [weak self] granted in
                if granted {
                    self?.showCamera()
                }
                else {
                    self?.showAlert(title: "Failed", msg: "Camera Access Required for ARCameraScreen!")
                }
            }
        }
        else {
            //ARSCNView will ask for permission by itself
            showCamera()
        }
    }
}


extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
}

extension ViewController: ARWallArtworkCameraDataSource {
    func arWallArtworkFetchArtworkModel(in vc: UIViewController, completion: @escaping (ArtworkModel?) -> ()) {
        //fail if no more artworks
        if newItmIdx > allArtworks.count - 1 {
            newItmIdx = 0
        }
        
        //fill
        completion(allArtworks[newItmIdx])

        //get next one
        newItmIdx += 1
    }
}
