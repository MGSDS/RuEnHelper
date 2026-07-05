// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RuEnHelper",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "RuEnHelper", path: "Sources/RuEnHelper")
    ]
)
