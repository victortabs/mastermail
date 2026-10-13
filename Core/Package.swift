// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MasterMailCore",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "MasterMailCore", targets: ["MasterMailCore"]),
    ],
    targets: [
        .target(name: "MasterMailCore"),
        .testTarget(name: "MasterMailCoreTests", dependencies: ["MasterMailCore"]),
    ]
)
