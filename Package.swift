// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RouterOffsetsLogic",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "RouterOffsetsLogic", path: "ios/Models", sources: ["Offsets.swift", "Sizes.swift"]),
        .testTarget(
            name: "OffsetsTests",
            dependencies: ["RouterOffsetsLogic"],
            path: "Tests/OffsetsTests"
        )
    ]
)
