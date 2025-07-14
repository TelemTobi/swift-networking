// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-networking",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
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
