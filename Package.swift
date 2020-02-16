// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "L10nGen",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "L10nGen",
            targets: ["L10nGen"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Files.git", from: "4.1.1"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "2.0.0"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.44.2"),
    ],
    targets: [
        .target(
            name: "L10nGen",
            dependencies: [
                "Files",
                "SwiftyJSON",
                "Yams",
                "SwiftFormat",
            ]
        ),
    ]
)
