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
  targets: [
    .binaryTarget(
        name: "PBBluetooth",
        path: "./Sources/PBBluetooth.xcframework")
  ]
)
