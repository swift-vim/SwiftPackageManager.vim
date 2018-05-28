// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPMVim",

    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "VimCore",
            type: .dynamic,
            targets: ["VimCore"]),
        .library(
            name: "VimInterface",
            targets: ["VimInterface"]),
    ],

    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Carthage/Commandant", from: "0.13.0"),
        .package(url: "https://github.com/jerrymarino/SwiftCompilationDatabase.git", .branch("master")),
        .package(url: "https://github.com/daniel-pedersen/SKQueue.git", from: "1.1.0")

    ],

    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "VimCore",
            dependencies: ["VimInterface"]),
        .target(name: "VimInterface",
            dependencies: []),
        .target(name: "EditorService",
            dependencies: ["LogParser", "SKQueue"]),
        .target(
            name: "SPMVim",
            dependencies: ["Commandant", "LogParser", "EditorService"]),
        .testTarget(
            name: "SPMVimTests",
            dependencies: ["EditorService"]),
        .testTarget(
            name: "VimInterfaceTests",
            dependencies: ["VimInterface"]),
    ]
)
