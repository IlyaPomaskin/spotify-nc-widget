// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "NowPlayingKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "NowPlayingKit", targets: ["NowPlayingKit"]),
    ],
    targets: [
        .target(name: "NowPlayingKit"),
        .testTarget(name: "NowPlayingKitTests", dependencies: ["NowPlayingKit"]),
    ]
)
