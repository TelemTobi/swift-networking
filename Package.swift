// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-networking",
    platforms: [.iOS("13.0"), .macOS("10.15.0")],
    products: [
        .library(name: "Networking", targets: ["Networking"]),
    ],
    targets: [
        .target(
            name: "Networking"
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"],
            resources: [.process("Resources")]
        )
    ]
)
