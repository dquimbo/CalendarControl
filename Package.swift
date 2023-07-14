// swift-tools-version: 5.8

import PackageDescription

let package = Package(
  name: "PBBluetooth",
  products: [
    .library(
        name: "PBBluetooth",
        targets: ["PBBluetooth"]),
  ],
  dependencies: [
      // Dependencies declare other packages that this package depends on.
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
