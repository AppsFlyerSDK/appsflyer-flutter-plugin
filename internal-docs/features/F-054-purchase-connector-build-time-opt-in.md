---
id: F-054
name: "Purchase Connector: Build-Time Opt-in"
type: purchaseValidation
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Purchase Connector adds optional native purchase-observation dependencies and code that core-attribution apps do not need. This feature is the build-time switch that includes and registers the real native implementation only when the consuming app opts in. Android compiles either the connector source set or an inert stub; CocoaPods conditionally includes the iOS Purchase Connector subspec and compile flag. Without the opt-in, the public Dart classes still compile but native channel calls cannot be served.

---

## Trigger
Not a runtime trigger — this is a build-time decision made once per app project when it configures its Gradle/CocoaPods/SPM build:
- **Android**: `android/build.gradle` reads `project.findProperty('appsflyer.enable_purchase_connector')?.toBoolean() ?: false`. The app sets `appsflyer.enable_purchase_connector=true` in its own `gradle.properties`.
- **iOS, CocoaPods**: `ios/appsflyer_sdk.podspec` checks `if defined?($AppsFlyerPurchaseConnector)`. The app sets `$AppsFlyerPurchaseConnector = true` in its own `Podfile` before running `pod install`.
- **iOS, SPM (as of F-060 — Swift Package Manager Support)**: there is no opt-in mechanism at all. `ios/appsflyer_sdk/Package.swift` only ever declares the Core target; it has no knowledge of `PurchaseConnector` and no equivalent of the podspec's `pod_target_xcconfig` macro injection. An SPM-only integration always behaves as "not opted in" — see Known Limitations.

---

## Call Chain
This feature has no runtime call chain — it is compile/build-time source-set and preprocessor branching:

```
Android (Gradle, evaluated at build configuration time):
  android/build.gradle
    def includeConnector = project.findProperty('appsflyer.enable_purchase_connector')?.toBoolean() ?: false
    sourceSets.main.java.srcDirs += includeConnector
        ? ['src/main/include-connector']   → real AppsFlyerPurchaseConnector.kt + ConnectorWrapper.kt (Play Billing Library, PurchaseClient)
        : ['src/main/exlude-connector']    → stub AppsFlyerPurchaseConnector.kt (no MethodChannel registered)

iOS (CocoaPods, evaluated at `pod install` time):
  ios/appsflyer_sdk.podspec
    if defined?($AppsFlyerPurchaseConnector)   ("$AppsFlyerPurchaseConnector = true" set in app's Podfile)
      s.default_subspecs = 'Core', 'PurchaseConnector'
        subspec 'PurchaseConnector' → depends on CocoaPods 'PurchaseConnector' pod
                                     → pod_target_xcconfig sets GCC_PREPROCESSOR_DEFINITIONS 'ENABLE_PURCHASE_CONNECTOR=1'
                                       and SWIFT_ACTIVE_COMPILATION_CONDITIONS '$(inherited) ENABLE_PURCHASE_CONNECTOR'
                                       (the Swift compiler ignores GCC_PREPROCESSOR_DEFINITIONS)
    else
      s.default_subspecs = 'Core'   (PurchaseConnector subspec/pod not included at all)

  ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift (compiled per the xcconfig condition above):
    public static func register(with registrar: FlutterPluginRegistrar) {
      #if ENABLE_PURCHASE_CONNECTOR
        PurchaseConnectorPlugin.register(with: registrar)
      #endif
      ...
    }
    (no bridging-header import is needed — both files compile into the same Swift module)

iOS (SPM, resolved at `swift build`/`flutter build` time — third gate, added by F-060):
  ios/appsflyer_sdk/Package.swift
    targets: [.target(name: "appsflyer_sdk", ...)]   — Core only, no PurchaseConnector target/product exists
    → ENABLE_PURCHASE_CONNECTOR is never defined for this target (SPM has no equivalent of CocoaPods' pod_target_xcconfig)
    → the same AppsflyerSdkPlugin.swift above compiles with the #if guard resolving false, identically to the CocoaPods not-opted-in path
```

---

## Files
| File | Role |
|------|------|
| `android/build.gradle` | Reads `appsflyer.enable_purchase_connector` Gradle property, switches `sourceSets.main.java.srcDirs` between the two variants |
| `android/src/main/include-connector/com/appsflyer/appsflyersdk/AppsFlyerPurchaseConnector.kt` | Real Android implementation: registers the `af-purchase-connector` MethodChannel and handles `configure`/`startObservingTransactions`/`stopObservingTransactions` |
| `android/src/main/include-connector/com/appsflyer/appsflyersdk/ConnectorWrapper.kt` | Wraps `PurchaseClient` (Play Billing Library) — only compiled in the include-connector variant |
| `android/src/main/exlude-connector/com/appsflyer/appsflyersdk/AppsFlyerPurchaseConnector.kt` | No-op stub: implements `FlutterPlugin` but registers no `MethodChannel` at all |
| `ios/appsflyer_sdk.podspec` | Defines the `PurchaseConnector` CocoaPods subspec conditionally on `$AppsFlyerPurchaseConnector`, and sets both the `ENABLE_PURCHASE_CONNECTOR=1` preprocessor macro and the matching `SWIFT_ACTIVE_COMPILATION_CONDITIONS` entry for that subspec only |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | `#if ENABLE_PURCHASE_CONNECTOR` guards the `PurchaseConnectorPlugin.register(with: registrar)` call |
| `ios/appsflyer_sdk/Package.swift` (added by F-060) | Declares only the Core target — has no PurchaseConnector target/product and no mechanism to define `ENABLE_PURCHASE_CONNECTOR`, so this gate is permanently "not opted in" for any SPM-only integration |
| `doc/purchase-connector.md` | App-facing opt-in instructions (`$AppsFlyerPurchaseConnector = true` in Podfile; `appsflyer.enable_purchase_connector=true` in gradle.properties) and an explicit "What Happens if You Use Dart Files Without Opting In?" section |

---

## Input / Output
| | |
|--|--|
| **Input** | Android: Gradle property `appsflyer.enable_purchase_connector` (string `"true"`/`"false"`, default `false`) set in the consuming app's `gradle.properties`. iOS: Ruby global `$AppsFlyerPurchaseConnector` set in the consuming app's `Podfile` before `pod install`; presence (not value) is what's checked (`defined?($AppsFlyerPurchaseConnector)`). |
| **Output** | Android: which `AppsFlyerPurchaseConnector.kt`/`ConnectorWrapper.kt` source set is compiled into the app's APK, and whether the `af-purchase-connector` MethodChannel gets a real handler. iOS: whether the `PurchaseConnector` pod/subspec and `ENABLE_PURCHASE_CONNECTOR` macro are present, which determines whether `PurchaseConnectorPlugin` is compiled and registered at all. |

---

## Tests
No dedicated test found — this is a Gradle/CocoaPods build-configuration concern with no Dart or native unit test coverage; verifying it requires two full builds (opted-in vs. opted-out) rather than a unit test, which the repo's `test/appsflyer_sdk_test.dart` does not attempt.

---

## Known Limitations
- The exclude-connector stub (`android/src/main/exlude-connector/.../AppsFlyerPurchaseConnector.kt`) is genuinely inert: it implements `FlutterPlugin.onAttachedToEngine`/`onDetachedFromEngine` as empty (`= Unit`) and never constructs a `MethodChannel` or sets a call handler. It does not throw and does not log a warning — it simply never responds. Any Dart call on the `af-purchase-connector` channel (`configure`, `startObservingTransactions`, etc.) in an app built without opting in will fail with Flutter's own `MissingPluginException`, not an AppsFlyer-authored error, making the failure mode confusing to diagnose (confirmed by reading the stub source directly).
- iOS has the same silent-gap behavior by omission rather than an explicit stub: if `$AppsFlyerPurchaseConnector` is undefined, the `PurchaseConnector` subspec/macro/registration are all compiled out, so `PurchaseConnectorPlugin` never registers a handler for `af-purchase-connector` either — same `MissingPluginException` outcome as Android, but reached via a completely different mechanism (absent Ruby global vs. an explicit empty Kotlin object), which is easy for engineers modifying one platform to forget applies to the other.
- **F-049 (Purchase Connector: Configuration & Lifecycle) and every other Purchase Connector Dart API are entirely meaningless without this feature being correctly opted into on both platforms** — the Dart-side classes (`PurchaseConnector`, `PurchaseConnectorConfiguration`, etc.) are always compiled into the plugin regardless of opt-in status, so an app can write code against them, pass static analysis, and still get runtime `MissingPluginException`s in production if it forgot the Podfile/gradle.properties step on either platform (`doc/purchase-connector.md` calls this out explicitly).
- The two opt-in mechanisms are asymmetric in strictness: Android checks a boolean value (`.toBoolean() ?: false`), so `appsflyer.enable_purchase_connector=false` or an unset/malformed property both cleanly resolve to "excluded." iOS checks mere *definedness* of `$AppsFlyerPurchaseConnector` (`defined?(...)`), so setting it to `false` in a Podfile still counts as "opted in" (`if defined?($AppsFlyerPurchaseConnector)` is true regardless of the assigned value) — a plausible copy-paste mistake (`$AppsFlyerPurchaseConnector = false` intending to disable it) silently enables the feature.
- **As of F-060 (Swift Package Manager Support), this gate has a third path with no opt-in mechanism at all**: an app integrated via SPM cannot enable Purchase Connector under any configuration this release — `ios/appsflyer_sdk/Package.swift` never defines `ENABLE_PURCHASE_CONNECTOR`, so the `#ifdef` guard always resolves false. Calling any Purchase Connector Dart API from an SPM-only integration fails with the same generic `MissingPluginException` described above for the CocoaPods not-opted-in case — this is not a new failure mode, but it is a third, permanent path to the same confusing outcome, not a temporary misconfiguration a developer can fix by setting a flag. Apps that need Purchase Connector must stay on CocoaPods until flutter/flutter#161182 (Flutter's own plugin tooling lacking conditional-compilation support) is resolved — see F-060 and [`internal-docs/researches/R-001-spm-support.md`](../researches/R-001-spm-support.md) for why SPM Package Traits do not currently offer a workaround.

---

## Dependencies
No required feature dependency. F-049 depends on this opt-in for native availability; F-060 documents that the current SPM product has no Purchase Connector opt-in path.
