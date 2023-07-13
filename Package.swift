// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "PBBluetooth",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "PBBluetooth",
            targets: ["PBBluetooth"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager",
            from: "1.0.0"
        )
    ],
    targets: [
        .binaryTarget(
            name: "PBBluetooth",
            path: "./Sources/PBBluetooth.xcframework")
    ]
)
