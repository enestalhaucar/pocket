// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "pocket",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "pocket",
            path: "Sources/pocket"
        )
    ]
)
