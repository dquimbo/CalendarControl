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
        path: "./build/PBBluetooth.xcframework")
  ]
)
