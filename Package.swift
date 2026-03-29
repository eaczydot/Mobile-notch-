// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BoringNotchShared",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "BoringNotchShared", targets: ["BoringNotchShared"]),
    ],
    targets: [
        .target(
            name: "BoringNotchShared",
            path: "Shared"
        ),
        .testTarget(
            name: "BoringNotchSharedTests",
            dependencies: ["BoringNotchShared"],
            path: "SharedTests"
        )
    ]
)
