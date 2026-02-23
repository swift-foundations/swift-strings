// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-strings",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Strings",
            targets: ["Strings"]
        ),
    ],
    dependencies: [
        .package(path: "../../swift-primitives/swift-string-primitives"),
        .package(path: "../../swift-standards/swift-iso-9899"),
    ],
    targets: [
        .target(
            name: "Strings",
            dependencies: [
                .product(name: "String Primitives", package: "swift-string-primitives"),
                .product(name: "ISO 9899", package: "swift-iso-9899"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("Lifetimes"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)


for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
