// swift-tools-version: 5.8

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
    .target(
        name: "PBBluetooth",
        dependencies: [
            .product(name: "iOSMcuManagerLibrary", package: "IOS-nRF-Connect-Device-Manager"),
        ],
        path: "./PBBluetooth/"
    )
  ]
)
