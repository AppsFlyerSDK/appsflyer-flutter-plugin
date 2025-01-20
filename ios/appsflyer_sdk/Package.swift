// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "appsflyer_sdk",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "appsflyer-sdk", type: .static, targets: ["appsflyer_sdk"])
    ],
    dependencies: [
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework", .upToNextMajor(from: "6.15.3")),
    ],
    targets: [
        .target(
            name: "appsflyer_sdk",
            dependencies: [
                .product(name: "AppsFlyerLib", package: "AppsFlyerFramework")
            ],
            cSettings: [
                .headerSearchPath("include/appsflyer_sdk")
            ]
        )
    ]
)
