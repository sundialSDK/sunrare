Pod::Spec.new do |s|
    s.name         = "SunRare"
    s.version      = "1.0.14"
    s.summary      = "ARKit wall artworks"
    s.description  = <<-DESC
    ARKit based wall artworks that provide ability to detect and visualize walls, place new Artwork and move it over the wall. Tap to select, reorder, go on link and change zoom for each Artwork. Save and load AR Artworks. Support easy integration by using Default AR Camera Screen or completely customizable UI by using ARWallArtworkControl directly with delegate and overlay provider usage.
    DESC
    s.homepage     = "http://www.google.com"
    s.license = { :type => 'Copyright', :text => <<-LICENSE
                   Copyright 2021
                   Permission is granted to private usage only...
                  LICENSE
                }
    s.author             = { "$(git config user.name)" => "$(git config user.email)" }
    s.source       = { :git => "git@github.com:sundialai/sunrare.git", :tag => "#{s.version}" }
    s.vendored_frameworks = "SunRare.xcframework"
    s.platform = :ios
    s.swift_version = "5.0"
    s.ios.deployment_target  = '13.0'
end

