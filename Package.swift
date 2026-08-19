// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EntitlementKit",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "EntitlementKitCore", targets: ["EntitlementKitCore"]),
        .library(name: "EntitlementKitRevenueCat", targets: ["EntitlementKitRevenueCat"]),
        .library(name: "EntitlementKitSwiftUI", targets: ["EntitlementKitSwiftUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.14.1"),
    ],
    targets: [
        .target(name: "EntitlementKitCore"),
        .target(
            name: "EntitlementKitRevenueCat",
            dependencies: ["EntitlementKitCore", .product(name: "RevenueCat", package: "purchases-ios")]
        ),
        .target(name: "EntitlementKitSwiftUI", dependencies: ["EntitlementKitCore"]),
        .testTarget(name: "EntitlementKitCoreTests", dependencies: ["EntitlementKitCore"]),
    ]
)
