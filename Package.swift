// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PeilTrail",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PeilTrail",
            path: "Sources/PeilTrail"
        )
    ]
)
