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
            try ARWallArtworkControl.defaultARCameraScreen(configuration: config, datasource: self, showIn: self)
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
        guard let tmp = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "AddNewArtworkScreen") as? AddNewArtworkScreen else { return }
        tmp.completion = completion
        vc.present(tmp, animated: true, completion: nil)
    }
}


class AddNewArtworkScreen: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var typeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var contentLinkField: UITextField!
    @IBOutlet weak var contentWidthField: UITextField!
    @IBOutlet weak var contentHeightField: UITextField!
    @IBOutlet weak var artworkNameField: UITextField!
    @IBOutlet weak var artistNameField: UITextField!
    @IBOutlet weak var ownerNameField: UITextField!
    @IBOutlet weak var nftLinkField: UITextField!
    @IBOutlet weak var addCustomButton: UIButton!
    
    var completion: ((ArtworkModel?) -> ())?
    
    //test all artworks
    let allArtworks = [ArtworkModel(contentLink: "https://helpx.adobe.com/content/dam/help/en/photoshop/using/convert-color-image-black-white/jcr_content/main-pars/before_and_after/image-before/Landscape-Color.jpg", contentType: .img, contentSize: CGSize(width: 1600, height: 664), artworkName: "Landscape", artistName: "Alen", ownerName: "Yahoo", nftLink: "https://www.google.com"),
                       
                       ArtworkModel(contentLink: "https://i.pinimg.com/736x/7e/1c/0b/7e1c0b3223789770299bc3b66b2fc2a0.jpg", contentType: .img, contentSize: CGSize(width: 607, height: 1080), artworkName: "Flower", artistName: "Sandra", ownerName: "Yahoo", nftLink: "https://www.rambler.ru"),
                       
                       ArtworkModel(contentLink: "https://interactive-examples.mdn.mozilla.net/media/cc0-images/grapefruit-slice-332-332.jpg", contentType: .img, contentSize: CGSize(width: 332, height: 332), artworkName: "Grapefruit", artistName: "Tubrok", ownerName: "Yahoo", nftLink: "https://www.yahoo.com"),
    
                       ArtworkModel(contentLink: "https://i.gifer.com/fxVE.gif", contentType: .gif, contentSize: CGSize(width: 540, height: 540), artworkName: "Animation", artistName: "GIFER", ownerName: "GIFER", nftLink: "https://i.gifer.com/fxVE.gif"),
    
                       ArtworkModel(contentLink: "https://img.rarible.com/prod/video/upload/prod-itemAnimations/0xd07dc4262bcdbf85190c01c996b4c06a461d2430:475644#t=0.1", contentType: .mp4, contentSize: CGSize(width: 1080, height: 1080), artworkName: "Rarible Artwork", artistName: "Rarible Artist", ownerName: "Rarible Owner", nftLink: "https://img.rarible.com/prod/video/upload/prod-itemAnimations/0xd07dc4262bcdbf85190c01c996b4c06a461d2430:475644#t=0.1")]
    
    @IBAction func pressedAddCustom() {
        guard let typeTtl = typeSegmentedControl.titleForSegment(at: typeSegmentedControl.selectedSegmentIndex),
            let type = ArtworkModel.ContentType(rawValue: typeTtl),
            let contentLink = contentLinkField.text,
            let contentWidthStr = contentWidthField.text, let contentWidth = Int(contentWidthStr),
            let contentHeightStr = contentHeightField.text, let contentHeight = Int(contentHeightStr),
            let artworkName = artworkNameField.text,
            let artistName = artistNameField.text,
            let ownerName = ownerNameField.text,
            let nftLink = nftLinkField.text else {
            
            //alert
            let alert = UIAlertController(title: "Sorry", message: "All Fields Should be Filled!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            show(alert, sender: self)
            
            return
        }
        
        let model = ArtworkModel(contentLink: contentLink, contentType: type,
                                 contentSize: CGSize(width: CGFloat(contentWidth), height: CGFloat(contentHeight)),
                                 artworkName: artworkName, artistName: artistName, ownerName: ownerName, nftLink: nftLink)
        completion?(model)
        
        dismiss(animated: true, completion: nil)
    }
    @IBAction func pressedAddGenerated() {
        //fill
        completion?(allArtworks.randomElement())
        
        //hide
        dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
}
