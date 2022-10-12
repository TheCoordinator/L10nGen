// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "L10nGen",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "L10nGen",
            targets: ["L10nGen"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/JohnSundell/Files.git", from: "4.1.1"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.0"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.50.1")
    ],
    targets: [
        .executableTarget(
            name: "L10nGen",
            dependencies: [
                "Files",
                "SwiftyJSON",
                "Yams",
                "SwiftFormat",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
