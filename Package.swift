// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GreePricePro",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "GreePricePro", targets: ["GreePricePro"])
    ],
    targets: [
        .executableTarget(
            name: "GreePricePro",
            path: "Sources"
        )
    ]
)
