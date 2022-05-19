// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "BCSwiftTor",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Tor",
            targets: ["Tor"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/WolfMcNally/WolfBase",
            from: "4.0.0"
        ),
    ],
    targets: [
        .target(
            name: "Tor",
            dependencies: ["TorBase", "WolfBase", "CLibEvent", "COpenSSL", "CTor"]
        ),
        .target(
            name: "CLibEvent"
        ),
        .target(
            name: "COpenSSL"
        ),
        .target(
            name: "CTor"
        ),
        .binaryTarget(
            name: "TorBase",
            path: "Frameworks/TorBase.xcframework"
        ),
        .testTarget(
            name: "TorTests",
            dependencies: ["Tor"]
        ),
    ]
)
