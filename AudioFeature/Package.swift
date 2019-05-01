// swift-tools-version:5.0
import PackageDescription

let package = Package(
  name: "AudioFeature",
  products: [
      // .executable(name: "AudioFeature", targets: ["AudioFeature"]),
      .library(name: "AudioFeature", targets: ["AudioFeature"]),
  ],
  dependencies: [
    .package(url:"https://github.com/jph00/BaseMath.git", from: "1.0.1"),
    .package(url: "https://github.com/realdoug/SwiftyMKL", from: "0.0.1")
  ],
  targets: [
    .systemLibrary(name: "CAudioFeature"),
    .target(
      name: "AudioFeature",
      dependencies: ["CAudioFeature", "BaseMath", "SwiftyMKL-Static"]
    ),
    .testTarget(
      name: "AudioFeatureTests",
      dependencies: ["AudioFeature"]
    )
  ]
)