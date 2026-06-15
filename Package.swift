// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ShelfDrop",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ShelfDrop", targets: ["ShelfDrop"])
    ],
    targets: [
        .executableTarget(
            name: "ShelfDrop",
            path: "Sources/ShelfDrop"
        )
    ]
)
