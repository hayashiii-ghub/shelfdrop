// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ShelfDrop",
    platforms: [
        .macOS("26.0")
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
