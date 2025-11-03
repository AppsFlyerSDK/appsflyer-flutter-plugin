// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let purchaseConnectorEnabled = ProcessInfo.processInfo.environment["ENABLE_PURCHASE_CONNECTOR"] == "1"

var dependencies: [Package.Dependency] = [
    .package(
        url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework",
        exact: "6.17.7"
    )
]

var appsflyerSdkDependencies: [Target.Dependency] = [
    .product(name: "AppsFlyerLib", package: "AppsFlyerFramework")
]

if purchaseConnectorEnabled {
    dependencies.append(
        .package(
            url: "https://github.com/AppsFlyerSDK/appsflyer-apple-purchase-connector",
            exact: "6.17.7"
        )
    )

    appsflyerSdkDependencies.append("purchase_connector")
}

let package = Package(
    name: "appsflyer_sdk",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "appsflyer-sdk", type: .static, targets: ["appsflyer_sdk"])
    ],
    dependencies: dependencies,
    targets: [
        .target(
            name: "appsflyer_sdk",
            dependencies: appsflyerSdkDependencies,
            cSettings: [
                .headerSearchPath("include/appsflyer_sdk")
            ]
        ),
        purchaseConnectorEnabled ?
            .target(
                name: "purchase_connector",
                dependencies: [
                    .product(name: "PurchaseConnector", package: "appsflyer-apple-purchase-connector")
                ]
            ) : nil
    ].compactMap { $0 }
)
