//
//  SnapshotScreen.swift
//  SunRare
//
//  Created by Alen Korbut on 05.08.2021.
//  Copyright © 2021 AI Sundial Corp. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func renderToImage(opaque: Bool) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, opaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        self.drawHierarchy(in: bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

class SnapshotScreen: UIViewController {
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameContainer: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageContainer.layer.shadowColor = UIColor.black.cgColor
        imageContainer.layer.borderColor = UIColor.white.cgColor
    }
    
    struct Model {
        let image: UIImage
        let model: ArtworkModel?
    }
    
    var model: Model?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageView.image = model?.image
        nameContainer.isHidden = model?.model == nil
        nameLabel.text = model?.model?.artworkName
        artistLabel.text = model?.model?.artistName
    }
    
    func getResultImage() -> UIImage? {
        return imageContainer.renderToImage(opaque: false)
    }
    
    @IBAction func pressedSave() {
        guard let img = getResultImage() else { return }

        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
    }
    @IBAction func pressedShare() {
        guard let img = getResultImage() else { return }
        
        let vc = UIActivityViewController(activityItems: [ img ], applicationActivities: nil)
        present(vc, animated: true, completion: nil)
    }
}
