// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PaleTrail",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PaleTrail",
            path: "Sources/PaleTrail"
        )
    ]
)
