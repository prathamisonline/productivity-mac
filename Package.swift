// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Lifesaver",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .executable(
            name: "Lifesaver",
            targets: ["Lifesaver"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Lifesaver",
            path: "Sources"
        )
    ]
)
