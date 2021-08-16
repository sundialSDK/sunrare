# ARWallArtwork

[![CocoaPods](https://img.shields.io/cocoapods/v/CameraManager.svg)](https://github.com/imaginary-cloud/CameraManager) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

ARKit based Wall Artworks that provide ability to detect and visualize walls, place new Artwork and move it over the wall. Tap to select, reorder, go on link and change zoom of each Artwork. Save and load AR Artworks. Support easy integration by using Default AR Camera Screen or completely customizable UI by using ARWallArtworkControl directly with delegate overlay provider usage.  

## Installation with CocoaPods

The easiest way to install the CameraManager is with [CocoaPods](http://cocoapods.org)

### Podfile

```ruby
use_frameworks!

pod 'ARWallArtwork', '~> 1.0'
```

## Installation with Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code.

Add `ARWallArtwork` as a dependency in your `Package.swift` file:

```
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/sundialai/ARWallArtwork", from: "1.0")
    ]
)
```

## Installation with Carthage

[Carthage](https://github.com/Carthage/Carthage) is another dependency management tool written in Swift.

Add the following line to your Cartfile:

```
github "sundialai/ARWallArtwork" >= 1.0
```

And run `carthage update` to build the dynamic framework.

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

```swift
extension ArtworksCameraScreen: ARWallArtworkControlDelegate {
func arWallArtworkControl(_ control: ARWallArtworkControl, showCoaching: Bool) {
    //TODO: 
}
func arWallArtworkControl(_ control: ARWallArtworkControl, didSelectArtwork model: ARWallArtwork.ArtworkModel, placing: Bool, zoom: Float) {
    //TODO:
}

func arWallArtworkControlDidUnselectArtwork(_ control: ARWallArtworkControl) {
    //TODO:
}
}
```

Support `ARWallArtworkControlOverlayProvider`: 

```swift
extension ArtworksCameraScreen: ARWallArtworkControlOverlayProvider {
    func arWallArtworkControl(_ control: ARWallArtworkControl, updateOverlayFor model: ArtworkModel, info: [ARWallArtwork.ArtworkSubNodeType : CGPoint]) {
        //TODO:
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
That's it, now you just need to provide implementation for `delegate` and `provider`, call `bindWallControl` when you'll have some map and customize all UI as you wish. NOTE: see details for delegate, provider, and another part of implementation next. 

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

### ARWallArtworkControlDelegate

`func arWallArtworkControl(_ control: ARWallArtworkControl, showCoaching: Bool)` handle coaching show / hide states, so in general should be used to update UI for display or hide all necessary UI while coaching active / inactive.  

`func arWallArtworkControl(_ control: ARWallArtworkControl, didSelectArtwork model: ARWallArtwork.ArtworkModel, placing: Bool, zoom: Float)` handle artwork selection, so in general should be use for update selected artwork info. 

`func arWallArtworkControlDidUnselectArtwork(_ control: ARWallArtworkControl)` handle unselection, so in general should be used for hide all UI that chain with selected artwork. 

### ARWallArtworkControlOverlayProvider

`func arWallArtworkControl(_ control: ARWallArtworkControl, updateOverlayFor model: ArtworkModel, info: [ARWallArtwork.ArtworkSubNodeType : CGPoint])`  Update Overlay action for some specific AR artwork node subnodes. Called on Main / UI Queue each time in renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) with already converted 2D coords from 3D coords. Should be used only for update overlay items locations. `For example`: you support delegate and handle didSelect to update title of active artwork, but you should update coordinate for that title label only in overlay provider if you want to move that label with AR Artwork Node. NOTE: subnodes grabbed from `ARWallArtworkControl.configuration.overlaySubNodes`, so if you're not set some subnode there then it wouldn't appear here (see `ARWallArtworkControl.Configuration` details next).












### Properties

You can set input device to front or back camera. `(Default: .Back)`

```swift
cameraManager.cameraDevice = .front || .back
```

You can specify if the front camera image should be horizontally fliped. `(Default: false)`

```swift
cameraManager.shouldFlipFrontCameraImage = true || false
```

You can enable or disable gestures on camera preview. `(Default: true)`

```swift
cameraManager.shouldEnableTapToFocus = true || false
cameraManager.shouldEnablePinchToZoom = true || false
cameraManager.shouldEnableExposure = true || false
```

You can set output format to Image, video or video with audio. `(Default: .stillImage)`

```swift
cameraManager.cameraOutputMode = .stillImage || .videoWithMic || .videoOnly
```

You can set the quality based on the [AVCaptureSession.Preset values](https://developer.apple.com/documentation/avfoundation/avcapturesession/preset) `(Default: .high)`

```swift
cameraManager.cameraOutputQuality = .low || .medium || .high || *
```

`*` check all the possible values [here](https://developer.apple.com/documentation/avfoundation/avcapturesession/preset)

You can also check if you can set a specific preset value:

```swift
if .cameraManager.canSetPreset(preset: .hd1280x720) {
     cameraManager.cameraOutputQuality = .hd1280x720
} else {
    cameraManager.cameraOutputQuality = .high
}
```

You can specify the focus mode. `(Default: .continuousAutoFocus)`

```swift
cameraManager.focusMode = .autoFocus || .continuousAutoFocus || .locked
```

You can specifiy the exposure mode. `(Default: .continuousAutoExposure)`

```swift
cameraManager.exposureMode = .autoExpose || .continuousAutoExposure || .locked || .custom
```

You can change the flash mode (it will also set corresponding flash mode). `(Default: .off)`

```swift
cameraManager.flashMode = .off || .on || .auto
```

You can specify the stabilisation mode to be used during a video record session. `(Default: .auto)`

```swift
cameraManager.videoStabilisationMode = .auto || .cinematic
```

You can get the video stabilization mode currently active. If video stabilization is neither supported or active it will return `.off`.

```swift
cameraManager.activeVideoStabilisationMode
```

You can enable location services for storing GPS location when saving to Camera Roll. `(Default: false)`

```swift
cameraManager.shouldUseLocationServices = true || false
```

In case you use location it's mandatory to add `NSLocationWhenInUseUsageDescription` key to the `Info.plist` in your app. [More Info](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy)

For getting the gps location when calling `capturePictureWithCompletion` you should use the `CaptureResult` as `data` (see [Example App](https://github.com/imaginary-cloud/CameraManager/blob/master/Example%20App/ViewController.swift)).

You can specify if you want to save the files to phone library. `(Default: true)`

```swift
cameraManager.writeFilesToPhoneLibrary = true || false
```

You can specify the album names for image and video recordings.

```swift
cameraManager.imageAlbumName =  "Image Album Name"
cameraManager.videoAlbumName =  "Video Album Name"
```

You can specify if you want to disable animations. `(Default: true)`

```swift
cameraManager.animateShutter = true || false
cameraManager.animateCameraDeviceChange = true || false
```

You can specify if you want the user to be asked about camera permissions automatically when you first try to use the camera or manually. `(Default: true)`

```swift
cameraManager.showAccessPermissionPopupAutomatically = true || false
```

To check if the device supports flash call:

```swift
cameraManager.hasFlash
```

To change flash mode to the next available one you can use this handy function which will also return current value for you to update the UI accordingly:

```swift
cameraManager.changeFlashMode()
```

You can even setUp your custom block to handle error messages:
It can be customized to be presented on the Window root view controller, for example.

```swift
cameraManager.showErrorBlock = { (erTitle: String, erMessage: String) -> Void in
    var alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (alertAction) -> Void in
    }))

    let topController = UIApplication.shared.keyWindow?.rootViewController

    if (topController != nil) {
        topController?.present(alertController, animated: true, completion: { () -> Void in
            //
        })
    }

}
```

You can set if you want to detect QR codes:

```swift
cameraManager.startQRCodeDetection { (result) in
    switch result {
    case .success(let value):
        print(value)
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

and don't forget to call `cameraManager.stopQRCodeDetection()` whenever you done detecting.

## Support

Supports iOS 9 and above. Xcode 11.4 is required to build the latest code written in Swift 5.2.

Now it's compatible with latest Swift syntax, so if you're using any Swift version prior to 5 make sure to use one of the previously tagged releases:

- for Swift 4 see: [v4.4.0](https://github.com/imaginary-cloud/CameraManager/tree/4.4.0).
- for Swift 3 see: [v3.2.0](https://github.com/imaginary-cloud/CameraManager/tree/3.2.0).

## License

Copyright © 2010-2020 [Imaginary Cloud](https://www.imaginarycloud.com/?utm_source=github). This library is licensed under the MIT license.

## About Imaginary Cloud

[![Imaginary Cloud](https://s3.eu-central-1.amazonaws.com/imaginary-images/Logo_IC_readme.svg)](https://www.imaginarycloud.com/?utm_source=github)

At Imaginary Cloud, we build world-class web & mobile apps. Our Front-end developers and UI/UX designers are ready to create or scale your digital product. Take a look at our [website](https://www.imaginarycloud.com/?utm_source=github) and [get in touch!](https://www.imaginarycloud.com/contacts/?utm_source=github) We'll take it from there.
