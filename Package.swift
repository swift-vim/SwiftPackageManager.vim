// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPMVim",

    products: [
        .library(
            name: "SPMVimPlugin",
            type: .dynamic,
            targets: ["SPMVimPlugin"]),
        .library(
            name: "EditorService",
            type: .dynamic,
            targets: ["EditorService"]),
    ],

    dependencies: [
        .package(url: "https://github.com/Carthage/Commandant",
            from: "0.13.0"),
        .package(url: "https://github.com/jerrymarino/SwiftCompilationDatabase.git",
            .branch("master")),
        .package(url: "https://github.com/daniel-pedersen/SKQueue.git",
             from: "1.1.0"),
        .package(url: "https://github.com/swift-vim/http",
             .revision("671be3123752a8eebd18dccb9321e1dfcae8f9c0")),
        .package(url: "https://github.com/swift-vim/SwiftForVim.git",
             .revision("898eb9cd7539d1fdc927ce6c657c64d05ef8a872"))
    ],

    targets: [
        .target(name: "EditorService",
            dependencies: ["LogParser", "SKQueue", "SPMProtocol"]),

        .target(
            name: "SPMVim",
            dependencies: ["Commandant", "LogParser", "EditorService"]),

        .target(
            name: "SPMVimPlugin",
            dependencies: [ "HTTP", "EditorService", "SPMProtocol"]),

        // Client <-> Server messages
        .target(name: "SPMProtocol"),

        .testTarget(
            name: "SPMVimTests",
            dependencies: ["SPMVimPlugin"]),

        /// SwiftForVim boilerplate
        .target(
            name: "StubVimImport",
            dependencies: ["VimAsync", "Vim"]),
    ]
)
