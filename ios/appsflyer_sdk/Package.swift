// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "appsflyer_sdk",
    platforms: [.iOS("12.0")],
    products: [
        .library(name: "appsflyer-sdk", targets: ["appsflyer_sdk"])
    ],
    dependencies: [
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework.git", from: "6.18.0")
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
