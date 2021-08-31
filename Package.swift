// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SunRare",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SunRare",
            targets: ["SunRare"]),
    ],
    targets: [
        .binaryTarget(
                    name: "SunRare",
                    path: "SunRare.xcframework"
                )
    ]
)
