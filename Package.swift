// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPMVim",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Carthage/Commandant", from: "0.13.0"),
        .package(url: "/Users/jerrymarino/Projects/SwiftCompilationDatabase/", .branch("master")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SPMVim",
            dependencies: ["Commandant", "LogParser"]),
        .testTarget(
            name: "SPMVimTests",
            dependencies: ["SPMVim"]),
    ]
)
