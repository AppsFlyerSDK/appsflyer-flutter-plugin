// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "appsflyer_sdk",
    platforms: [.iOS("13.0")],
    products: [
        .library(name: "appsflyer-sdk", targets: ["appsflyer_sdk"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // Must match the AppsFlyerFramework version AppsFlyerRPC's own podspec pins
        // exactly, or SPM and CocoaPods consumers link different native SDKs from the
        // same plugin release.
        .package(
            url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework.git",
            exact: "7.0.4"
        )
    ],
    targets: [
        .binaryTarget(
            name: "AppsFlyerRPC",
            url: "https://github.com/AppsFlyerSDK/appsflyer-apple-rpc/releases/download/7.0.41/AppsFlyerRPC-static.xcframework.zip",
            checksum: "4c44d2454f065cb5ca9d740d7fd403ec0c47961eb8bf6532da5dda9d82a96709"
        ),
        .target(
            name: "appsflyer_sdk",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "AppsFlyerLib", package: "AppsFlyerFramework"),
                "AppsFlyerRPC"
            ],
            path: "Sources/appsflyer_sdk"
        )
    ]
)
