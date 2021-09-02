#!/bin/bash
cd `[SunRare sources folder path]`
xcodebuild archive -scheme SunRare -destination "generic/platform=iOS" -archivePath ../output/SunRare-iOS
xcodebuild archive -scheme SunRare -destination "generic/platform=iOS Simulator" -archivePath ../output/SunRare-iOS-Sim
xcodebuild -create-xcframework -framework ../output/SunRare-iOS.xcarchive/Products/Library/Frameworks/SunRare.framework/ -framework ../output/SunRare-iOS-Sim.xcarchive/Products/Library/Frameworks/SunRare.framework/ -output ../SunRare.xcframework
rm -R ../output/
