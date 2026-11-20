// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "iosUI-sdk",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "UIBehaviorCore", targets: ["UIBehaviorCore"]),
    .library(name: "UIBehaviorSwiftUI", targets: ["UIBehaviorSwiftUI"]),
    .library(name: "UIBehaviorUIKit", targets: ["UIBehaviorUIKit"]),
  ],
  targets: [
    .target(name: "UIBehaviorCore"),
    .target(name: "UIBehaviorNative", dependencies: ["UIBehaviorCore"]),
    .target(name: "UIBehaviorTextKit", dependencies: ["UIBehaviorCore"]),
    .target(
      name: "UIBehaviorSwiftUI",
      dependencies: ["UIBehaviorCore", "UIBehaviorTextKit", "UIBehaviorNative"]),
    .target(
      name: "UIBehaviorUIKit",
      dependencies: [
        "UIBehaviorCore", "UIBehaviorSwiftUI", "UIBehaviorTextKit", "UIBehaviorNative",
      ]),
    .testTarget(name: "UIBehaviorCoreTests", dependencies: ["UIBehaviorCore"]),
  ]
)
