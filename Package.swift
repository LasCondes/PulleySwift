// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PulleySwift",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PulleyCore",
            targets: ["PulleyCore"]
        ),
        .library(
            name: "PulleyStandards",
            targets: ["PulleyStandards"]
        ),
        .library(
            name: "PulleyBOM",
            targets: ["PulleyBOM"]
        ),
        .executable(
            name: "ShaftExample",
            targets: ["ShaftExample"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/LasCondes/AxiSymFEA.git", from: "1.0.0")
    ],
    targets: [
        // Core domain models and data structures
        .target(
            name: "PulleyCore"
        ),

        // Engineering standards (ANSI, DIN15018, AS1403)
        .target(
            name: "PulleyStandards",
            dependencies: [
                "PulleyCore",
                .product(name: "AxiSymFEA", package: "AxiSymFEA")
            ]
        ),

        // Bill of Materials
        .target(
            name: "PulleyBOM",
            dependencies: ["PulleyCore"]
        ),

        // Examples
        .executableTarget(
            name: "ShaftExample",
            dependencies: [
                "PulleyCore",
                .product(name: "AxiSymFEA", package: "AxiSymFEA")
            ],
            path: "Examples"
        ),

        // Tests
        .testTarget(
            name: "PulleyCoreTests",
            dependencies: ["PulleyCore"]
        ),
        .testTarget(
            name: "PulleyStandardsTests",
            dependencies: ["PulleyStandards"]
        ),
        .testTarget(
            name: "PulleyBOMTests",
            dependencies: ["PulleyBOM"]
        ),
    ]
)
