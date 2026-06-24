// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// This manifest provides Swift Package Manager support for the AppsFlyer "Core"
// integration (the default subspec). The optional PurchaseConnector subspec is
// intentionally NOT included here — it remains CocoaPods-only for now because of
// the open Flutter limitation tracked in flutter/flutter#161182. Apps that use
// PurchaseConnector continue to opt in via the $AppsFlyerPurchaseConnector Podfile
// flag and CocoaPods; everyone else gets SPM support and loses the warning.

let package = Package(
    name: "appsflyer_sdk",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "appsflyer_sdk", targets: ["appsflyer_sdk"])
    ],
    dependencies: [
        // Static variant matches the podspec's `static_framework = true`.
        // Product "AppsFlyerLib-Static" wraps the binary target "AppsFlyerLib",
        // so the existing `#import <AppsFlyerLib/AppsFlyerLib.h>` keeps resolving.
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static.git", exact: "6.18.0")
    ],
    targets: [
        .target(
            name: "appsflyer_sdk",
            dependencies: [
                .product(name: "AppsFlyerLib-Static", package: "AppsFlyerFramework-Static")
            ],
            // Implementation (.m) files in Sources/appsflyer_sdk/, public headers (.h)
            // in Sources/appsflyer_sdk/include/appsflyer_sdk/. The header search path
            // lets the .m/.h files resolve their siblings by bare name.
            cSettings: [
                .headerSearchPath("include/appsflyer_sdk")
            ]
        )
    ]
)
