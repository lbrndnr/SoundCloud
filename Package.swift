// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SoundCloud",
    platforms: [.macOS(.v10_15), .iOS(.v14)],
    products: [
        .library(name: "SoundCloud", targets: ["SoundCloud"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SoundCloud",
            dependencies: []),
        .testTarget(
            name: "SoundCloudTests",
            dependencies: ["SoundCloud"]),
    ]
)
