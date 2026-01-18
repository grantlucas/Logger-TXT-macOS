// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Logger-TXT",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LoggerTXT", targets: ["LoggerTXT"]),
        .library(name: "LoggerTXTCore", targets: ["LoggerTXTCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "LoggerTXT",
            dependencies: [
                "LoggerTXTCore",
                "KeyboardShortcuts",
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern")
            ]
        ),
        .target(
            name: "LoggerTXTCore"
        ),
        .testTarget(
            name: "LoggerTXTCoreTests",
            dependencies: ["LoggerTXTCore"]
        )
    ]
)
