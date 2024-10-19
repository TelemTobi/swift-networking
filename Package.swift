// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Flux",
    platforms: [.iOS("13.0"), .macOS("10.15.0")],
    products: [
        .library(
            name: "Flux",
            targets: ["Flux"]
        ),
    ],
    targets: [
        .target(
            name: "Flux"
        ),
        .testTarget(
            name: "FluxTests",
            dependencies: ["Flux"]
        )
    ]
)
