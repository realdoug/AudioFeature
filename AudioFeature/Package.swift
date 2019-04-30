// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name: "AudioFeature",
  products: [
      // .executable(name: "AudioFeature", targets: ["AudioFeature"]),
      .library(name: "AudioFeature", targets: ["AudioFeature"]),
  ],
  targets: [
    .systemLibrary(name: "CAudioFeature"),
    .target(
      name: "AudioFeature",
      dependencies: ["CAudioFeature"]
    )
  ]
)