# SunRare

ARKit based wall artworks that provide ability to detect and visualize walls, place new Artwork and move it over the wall. Tap to select, reorder, go on link and change zoom for each Artwork. Save and load AR Artworks. Support easy integration by using Default AR Camera Screen or completely customizable UI by using ARWallArtworkControl directly with delegate and overlay provider usage.  

## Requirements

- `iOS 13` and above. 
- `Swift 5`. 
- `A12 chip` compatible devices
- `Privacy - Camera Usage Description` in info.plist
- `Privacy - Photo Library Additions Usage Description` in info.plist
- `iOS Device Only`. Simulator not supported!

## Installation with CocoaPods

sunrare is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SunRare", "1.0.0", :source => "git@github.com:sundialai/sundial-spec.git"
```

## Installation with Swift Package Manager

sunrare is available through [SwiftPackageManager](https://developer.apple.com/documentation/swift_packages). To install
it, simply add the following link in `git@github.com:tubrokAlien/sunrare-framework.git` inside "Choose Package Repository" window on XCode. 

## How to use

To use it you need to `import ARWallArtwork` and add required  `Privacy - Camera Usage Description` and `Privacy - Photo Library Additions Usage Description` to Info.plist and just need to call `ARWallArtworkControl.presentDefaultARCameraScreen` from some view controller with some custom configuration for load and save artworks if needed. 

```swift
let name = "myFirstArtwork.artworkmap"
let mapURL: URL? = (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false))?.appendingPathComponent(name)

//use the same file URL for load and save!
var config = DefaultARCameraConfiguration()
config.worldMapLoadURL = mapURL
config.worldMapSaveURL = mapURL

//show it
do {
    try ARWallArtworkControl.presentDefaultARCameraScreen(configuration: config, datasource: self, in: self)
}
catch let e {
    ProgressHUD.showError(e.localizedDescription, image: nil, interaction: false)
}
```

Also if you want to provide ability to choose and place new artworks you need to support `ARWallArtworkCameraDataSource`, otherwise default wall artwork camera could be used as simple viewer for some already exist artworks.

```swift
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
```

ARSCNView will ask for permission by itself, but recommend to ask camera permissions before present default artwork camera, so you just need to call:

```swift
ARWallArtworkControl.requestCameraAccess { granted in
    if granted {
        //TODO: call ARWallArtworkControl.presentDefaultARCameraScreen
    }
    else {
        //TODO: show alert: AR screen require camera permission
    }
}
```

That's it, this is how it easy. 

## Cache Content

If you want to cache AR content then you need to provide ability for it by yourself. Basically SunRare give public protocol `ARWallArtworkCacheProvider` that should be supported and set to `ARWallArtworkControl.cacheProvider`. By default AR content are not cached. 

```swift
ARWallArtworkControl.cacheProvider = self //ARWallArtworkCacheProvider control
```

## Customize UI and Behaviour

If you want to customize UI and support whole power of `ARWallArtwork` framework you need to support `ARWallArtworkControl` directly with delegate and overlay provider instead of use `ARWallArtworkControl.presentDefaultARCameraScreen`.

At first you need to create some view controller with ARSCNView inside of it: 

```swift
class ArtworksCameraScreen: UIViewController {
    @IBOutlet weak var sceneView: ARSCNView!
}
```

Next you need to create `ARWallArtworkControl` property inside of your screen:

```swift
private lazy var wallArtwork: ARWallArtworkControl = {
    var tmp = ARWallArtworkControl()
    tmp.delegate = self
    tmp.overlayProvider = self
    return tmp
}()
```

Support `ARWallArtworkControlDelegate`: 

`func arWallArtworkControl(_ control: ARWallArtworkControl, showCoaching: Bool)` handle coaching show / hide states, so in general should be used to update UI for display or hide all necessary UI while coaching active / inactive.  

```swift
func arWallArtworkControl(_ control: ARWallArtworkControl, showCoaching: Bool) {
    overlayContainer.isHidden = showCoaching
}
```

`func arWallArtworkControl(_ control: ARWallArtworkControl, didSelectArtwork model: ARWallArtwork.ArtworkModel, placing: Bool, zoom: Float)` handle artwork selection, so in general should be use for update selected artwork info. 

```swift
func arWallArtworkControl(_ control: ARWallArtworkControl, didSelectArtwork model: ArtworkModel, placing: Bool, zoom: Float) {
    self.activeModel = model
    titleLabel.text = model.imageName
    placingIndicator.isHidden = !placing
    zoomLabel.text = "\(Int(zoom * 100))%"
}
```

`func arWallArtworkControlDidUnselectArtwork(_ control: ARWallArtworkControl)` handle unselection, so in general should be used for hide all UI that chain with selected artwork. 

```swift
func arWallArtworkControlDidUnselectArtwork(_ control: ARWallArtworkControl) {
    activeModel = nil
    titleLabel.text = ""
    placingIndicator.isHidden = true
    zoomLabel.isHidden = true
}
```

Support `ARWallArtworkControlOverlayProvider`: 

`func arWallArtworkControl(_ control: ARWallArtworkControl, updateOverlayFor model: ArtworkModel, info: [ARWallArtwork.ArtworkSubNodeType : CGPoint])`  Update Overlay action for some specific AR artwork node subnodes. Called on Main / UI Queue each time in renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) with already converted 2D coords from 3D coords. Should be used only for update overlay items locations. `For example`: you support delegate and handle didSelect to update title of active artwork, but you should update coordinate for that title label only in overlay provider if you want to move that label with AR Artwork Node. NOTE: subnodes grabbed from `ARWallArtworkControl.configuration.overlaySubNodes`, so if you're not set some subnode there then it wouldn't appear here (see `ARWallArtworkControl.Configuration` details next).


```swift
func arWallArtworkControl(_ control: ARWallArtworkControl, updateOverlayFor model: ArtworkModel, info: [ArtworkSubNodeType : CGPoint]) {
    //reusable
    let setTr: (UIView, CGPoint)->() = { tmp, pt in
        tmp.transform = CGAffineTransform.identity
        let fix = tmp.frame
        tmp.transform = CGAffineTransform(translationX: pt.x - fix.midX, y: pt.y - fix.midY)
    }
    
    //set zoom loc
    if let tmp = info[.zoom] {
        setTr(zoomLabel, tmp)
    }
    
    //set title loc
    if let tmp = info[.arrow] {
        setTr(titleLabel, CGPoint(x: tmp.x, y: tmp.y - titleLabel.bounds.height))
    }
}
```

Next you need to bind  `ARWallArtworkControl` to your scene: 

```swift
func bindWallControl(map: ARWorldMap?) throws {
    var wallConfig = ARWallArtworkControl.Configuration()
    wallConfig.initialWorldMap = map
    //TODO: config additional params if needed
    try wallArtwork.bindToARScene(sceneView, config: wallConfig)
}
```
That's it, next you should call `bindWallControl` when you'll have some map and customize all UI as you wish. 

### ArtworkMap 

ARWallArtwork framework provide easy to use ArtworkMap class helper that give you ability to save and load artworks map from / to URL and could be used in case of `ARWallArtworkControl` directly support inside custom UI.

Here is load logic: 

```swift
ArtworkMap.load(url: url).then { [weak self] map in
    //TODO: use map 
}.catch { [weak self] error in
    //TODO: show error
}
```

Here is save logic, NOTE: you need to provide `ARSession` from `ARSCNView`: 

```swift
//required session
guard let session = sceneView?.session else {
    return Promise(rejected: MapError.sessionRequired)
}
//save scene
ArtworkMap.save(session: session, url: url).then { [weak self] map in
    //TODO: use map 
}.catch { [weak self] error in
    //TODO: show error
}
```

### ARWallArtworkControl public actions

`ARWallArtworkControl` contain some public methods that allow to: 

Bind to `ARSCNView` action. Should be called on initial step of config:
```swift
func bindToARScene(_ sceneView: ARSCNView, config: Configuration = Configuration())
```

Unbind action. Should be used on screen unload:
```swift
func unbind()
```

Add active placing node to screen constantly:
```swift
func addActiveNode()
```

Remove active placing node from screen:
```swift
func removeActiveNode()
```

Add new artwork on active detected wall (raycast mid point of screen to 3D). Newly added node moved with phone and should be stored with `addActiveNode()` or removed by `removeActiveNode()`:
```swift
func placeNewArtwork(model: ArtworkModel)
```

Reorder artwork allow to place artwork on new location or remove:
```swift
func reorderArtwork(model: ArtworkModel)
```

Snapshot current active node or whole screen:
```swift
func snapshot() -> (image: UIImage, model: ArtworkModel?)?
```

Zoom selected artwork. Set 0 - 1 value:
```swift
func zoomSelectedArtwork(perc: Float)
```

Save scene : 
```swift
func saveScene(url: URL) -> Promise<Void>
```

### ArtworkModel properties

General artwork model for sunrare framework that used inside AR Node, Anchor and used for save / load inside ARWorldMap. 

Content properties. Link that loaded and displayed. Type and size for that content: 
```swift
public var contentLink: String
public var contentType: ContentType
public var contentSize: CGSize
```

Some artwork name properties:
```swift
public var artworkName: String
public var artistName: String
public var ownerName: String
```

NFT link:
```swift
public var nftLink: String
```

### ARWallArtworkControl.Configuration properties

If `ARWallArtworkControl` used directly in case of custom UI implementation then could be used different configuration:

By default raycast plane geometry used and it's enough for most purposes, but if need it could be changed to any other type that apple allow: 
```swift
public var allowingRaycastTarget: ARRaycastQuery.Target = .existingPlaneGeometry
```

By default walls are not visualized. Could be used custom color to visualize detected walls
```swift
public var visualizeDetectedPlane: UIColor? = nil
```

Here need to set exact sub nodes that would be used in screen overlay: 
```swift
public var overlaySubNodes: Set<ArtworkSubNodeType> = Set([])

//for example in default camera screen used:
//wallConfig.overlaySubNodes = Set([.arrow,.reorder,.link,.zoom])
```

Each AR artwork node subnode could be configured to show some kind of content (image or color). By default subnodes used just as anchors for screen overlay, except content image subnode:
```swift
public var artworkSubNodesContentInfo: [ArtworkSubNodeType: Any] = [:]

//for example in default camera screen used:
//wallConfig.artworkSubNodesContentInfo = [.artworkPlaceholder: img]
```

True - coaching will disppear when some real wall detected and (if some initial world map set) some saved artwork node detected. False - only some real wall detected. False is default value.
```swift
public var automaticallyCoaching: Bool = false
```

To show some already exist artworks need to set initialWorldMap: 
```swift
public var initialWorldMap: ARWorldMap? = nil
```


## Author

AI Sundial Corp (Sundial)

## License

Private use only license

//TODO: !!!

## About AI Sundial Corp

//TODO: !!!
