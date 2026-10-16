// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GridTerm",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "GridTerm", targets: ["GridTerm"]),
        .library(name: "GridTermKit", targets: ["GridTermKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.20.0")
    ],
    targets: [
        .target(
            name: "GridTermKit",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm")
            ],
            path: "Sources/GridTermKit"
        ),
        .executableTarget(
            name: "GridTerm",
            dependencies: [
                "GridTermKit",
                .product(name: "SwiftTerm", package: "SwiftTerm")
            ],
            path: "Sources/GridTerm"
        ),
        .testTarget(
            name: "GridTermTests",
            dependencies: [
                "GridTermKit",
                .product(name: "SwiftTerm", package: "SwiftTerm")
            ],
            path: "Tests/GridTermTests"
        ),
    ]
)
