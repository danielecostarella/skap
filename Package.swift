// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "skap",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SkapCore",
            targets: ["SkapCore"]
        ),
        .executable(
            name: "Skap",
            targets: ["SkapGUI"]
        ),
        .executable(
            name: "skap",
            targets: ["skap-cli"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "SkapCore",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .executableTarget(
            name: "SkapGUI",
            dependencies: ["SkapCore"],
            path: "Sources/SkapGUI",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .executableTarget(
            name: "skap-cli",
            dependencies: [
                "SkapCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/skap-cli",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "SkapCoreTests",
            dependencies: ["SkapCore"]
        )
    ]
)
