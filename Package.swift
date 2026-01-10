// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let upcomingSwiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency"),
    .enableUpcomingFeature("ExistentialAny"),
    // Optional, only if you use it:
    // .enableUpcomingFeature("ImplicitOpenExistentials"),
]

let package = Package(
    name: "SmartAsyncImage",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SmartAsyncImage",
            targets: ["SmartAsyncImage"]
        ),
    ],
    targets: [
        .target(
            name: "SmartAsyncImage",
            swiftSettings: upcomingSwiftSettings
        ),
        .testTarget(
            name: "SmartAsyncImageTests",
            dependencies: ["SmartAsyncImage"],
            swiftSettings: upcomingSwiftSettings
        ),
    ]

    // Key point:
    // If you want "upcoming features" (incremental Swift 6 hardening),
    // do NOT pin full Swift 6 language mode here.
    // Remove swiftLanguageModes entirely.
    //
    // , swiftLanguageModes: [.v6]
)
