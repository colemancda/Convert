// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "Convert",
    products: [
        .library(
            name: "Convert",
            targets: ["Convert"]),
        .executable(
            name: "Convert",
            targets: ["Convert"])
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.1.0"),
        .package(url: "https://github.com/JohnSundell/Files.git", from: "2.2.1"),
    ],
    targets: [
        .target(
            name: "Convert",
            dependencies: ["ShellOut", "Files"]),
    ]
)
