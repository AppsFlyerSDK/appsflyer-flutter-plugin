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
        // exactly (7.0.13 -> 7.0.2), or SPM and CocoaPods consumers link different
        // native SDKs from the same plugin release.
        .package(
            url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework.git",
            exact: "7.0.2"
        )
    ],
    targets: [
        .binaryTarget(
            name: "AppsFlyerRPC",
            url: "https://github.com/AppsFlyerSDK/appsflyer-apple-rpc/releases/download/7.0.13/AppsFlyerRPC-static.xcframework.zip",
            checksum: "e6ab48450c2f2bec204a8f6298e4b5859db6bf8232819b388d741aea59c567d1"
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
