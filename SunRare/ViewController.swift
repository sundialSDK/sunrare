//
//  ViewController.swift
//  SunRare
//
//  Created by Alen Korbut on 03.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import UIKit
import ARWallArtwork
import AVFoundation
import ARKit
import ProgressHUD

class ViewController: UIViewController {
    @IBOutlet weak var checkCameraAccessBeforeSwitch: UISwitch!
    @IBOutlet weak var worldMapTextField: UITextField!
    
    //test all artworks
    let allArtworks = [ARWallArtwork.ArtworkModel(imageLink: "https://helpx.adobe.com/content/dam/help/en/photoshop/using/convert-color-image-black-white/jcr_content/main-pars/before_and_after/image-before/Landscape-Color.jpg", imageSize: CGSize(width: 1600, height: 664), imageName: "Landscape", artistName: "Alen", link: "https://www.google.com"),
                       ARWallArtwork.ArtworkModel(imageLink: "https://i.pinimg.com/736x/7e/1c/0b/7e1c0b3223789770299bc3b66b2fc2a0.jpg", imageSize: CGSize(width: 607, height: 1080), imageName: "Flower", artistName: "Sandra", link: "https://www.rambler.ru"),
                       ARWallArtwork.ArtworkModel(imageLink: "https://interactive-examples.mdn.mozilla.net/media/cc0-images/grapefruit-slice-332-332.jpg", imageSize: CGSize(width: 332, height: 332), imageName: "Grapefruit", artistName: "Tubrok", link: "https://www.yahoo.com")]
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
            ProgressHUD.showError(e.localizedDescription, image: nil, interaction: false)
        }
    }
}


extension ViewController {
    @IBAction func unwindArCamera(segue: UIStoryboardSegue) {
        //skip
    }
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
            completion(nil)
            return
        }

        //fill
        completion(allArtworks[newItmIdx])

        //get next one
        newItmIdx += 1
    }
}
