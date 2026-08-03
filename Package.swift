// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DopaGak",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DopaGak", targets: ["DopaGak"])
    ],
    targets: [
        .executableTarget(
            name: "DopaGak",
            path: "Sources/ShelfDrop"
        ),
        .testTarget(
            name: "DopaGakTests",
            dependencies: ["DopaGak"],
            path: "Tests/ShelfDropTests"
        )
    ]
)
