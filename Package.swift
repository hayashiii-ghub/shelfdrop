// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ShelfDrop",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "ShelfDrop", targets: ["ShelfDrop"])
    ],
    targets: [
        .executableTarget(
            name: "ShelfDrop",
            path: "Sources/ShelfDrop"
        ),
        .testTarget(
            name: "ShelfDropTests",
            dependencies: ["ShelfDrop"],
            path: "Tests/ShelfDropTests"
        )
    ]
)
