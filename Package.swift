// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "iPaper",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "iPaper", targets: ["iPaper"]),
        .executable(name: "TestRunner", targets: ["TestRunner"]),
        .executable(name: "Benchmark", targets: ["Benchmark"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "iPaperLib",
            dependencies: [],
            path: "Sources/iPaperLib",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "iPaper",
            dependencies: ["iPaperLib"],
            path: "Sources/iPaper"
        ),
        .executableTarget(
            name: "TestRunner",
            dependencies: ["iPaperLib"],
            path: "Tests/TestRunner"
        ),
        .executableTarget(
            name: "Benchmark",
            dependencies: ["iPaperLib"],
            path: "Tests/Benchmark"
        )
    ]
)
