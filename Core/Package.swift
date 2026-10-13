// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MasterMailCore",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "MasterMailCore", targets: ["MasterMailCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.11.1"),
    ],
    targets: [
        .target(name: "MasterMailCore", dependencies: [.product(name: "GRDB", package: "GRDB.swift")]),
        .testTarget(name: "MasterMailCoreTests", dependencies: ["MasterMailCore"]),
    ]
)
