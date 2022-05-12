// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "VoxelView",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "VoxelView",
            targets: ["VoxelView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/heestand-xyz/DisplayLink", from: "1.0.2"),
    ],
    targets: [
        .target(
            name: "VoxelView",
            dependencies: ["DisplayLink"]),
    ]
)
