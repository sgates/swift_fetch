// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-fetch",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "swift-fetch",
            targets: ["swift-fetch"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0")
    ],
    targets: [
        .executableTarget(
            name: "swift-fetch",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "swift-fetchTests",
            dependencies: [
                "swift-fetch",
                "SwiftCheck"
            ],
            path: "Tests"
        )
    ]
)
