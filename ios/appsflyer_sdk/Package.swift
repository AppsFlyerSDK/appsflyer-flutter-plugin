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
        .package(
            url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework.git",
            exact: "7.0.1"
        )
    ],
    targets: [
        .binaryTarget(
            name: "AppsFlyerRPC",
            url: "https://github.com/AppsFlyerSDK/appsflyer-apple-rpc/releases/download/7.0.12/AppsFlyerRPC-static.xcframework.zip",
            checksum: "14484bce262c2bea03cb4fb0ca85818560dd72831915246f5cc2686eb196f87f"
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
