---
id: F-012
name: Manual GDPR/DMA Consent API
type: sdkCore
platform: both
status: active
last_verified: 2026-08-25
depends_on: []
---

## Business Purpose
Apps that do not rely on a TCF-compatible CMP (F-011) still need a way to legally record and forward the user's GDPR/DMA consent decisions before AppsFlyer collects or uses their data. `setConsentData` is the manual counterpart: the app itself determines whether GDPR applies and what the user consented to, then hands that decision to the SDK explicitly. Getting this right is a legal-compliance requirement, not a UX nicety — incorrect or missing consent forwarding can put the integrating company in violation of GDPR/DMA.

SDK 7 replaces the previous two-variant surface (the deprecated `AppsFlyerConsent` object and `setConsentDataV2`) with a single flat method whose named parameters map one-to-one onto the RPC contract. There is no consent model class to construct and no deprecated alternative to choose between.

---

## Trigger
Called by the host app once consent has been captured from the user's own consent UI. Per `doc/consent-dma.md`, call it after `init()` and before the first `start()`, so the launch request carries the correct state. The native SDK retains the value across foreground cycles in the same process, but not across a cold start; supply it once per process launch.

---

## Call Chain
A single flat method dispatches the `setConsentData` RPC on both platforms. Dart forwards the payload as supplied.

```
AppsFlyerSdk.setConsentData({isUserSubjectToGDPR, hasConsentForDataUsage,
                             hasConsentForAdsPersonalization, hasConsentForAdStorage})
                                                                      [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('setConsentData', {isUserSubjectToGDPR, hasConsentForDataUsage,
                                      hasConsentForAdsPersonalization, hasConsentForAdStorage})
    → _invokeNullableRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.executeRpc → dispatchRpc → AppsFlyerRpcHandler
        → AppsFlyerConsent → AppsFlyerLib.getInstance().setConsentData(consent)
      → iOS: AppsflyerSdkPlugin.executeRpc → dispatchRpc → AppsFlyerRPCBridge.executeJson
        → AppsFlyerConsent → [[AppsFlyerLib shared] setConsentData:consentData]
  → PlatformException is converted to AppsFlyerException
```

On iOS, `AFRPCSetConsentDataRequest` requires `isUserSubjectToGDPR` and accepts nullable consent fields; neither platform's RPC layer enforces completeness when GDPR applies — matching native `AppsFlyerConsent` construction.

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setConsentData({required bool isUserSubjectToGDPR, bool? hasConsentForDataUsage, bool? hasConsentForAdsPersonalization, bool? hasConsentForAdStorage})` |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Generic `executeRpc` → `dispatchRpc` routing `setConsentData` to `AppsFlyerRpcHandler` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | Generic `executeRpc` → `dispatchRpc` forwarding `setConsentData` to `AppsFlyerRPCBridge` |
| `doc/consent-dma.md` | Integration guide for both the CMP-automatic (F-011) and manual (this feature) consent paths |
| `doc/migration-guide.md` | Maps the removed `setConsentDataV2(...)` / `setConsentData(AppsFlyerConsent)` variants onto the flat `setConsentData(...)` API |

---

## Input / Output
| | |
|--|--|
| **Input** | `isUserSubjectToGDPR` (`bool`, required). The three consent fields are optional `bool?` values — omit or pass `null` for non-GDPR users (`isUserSubjectToGDPR: false`), matching native `AppsFlyerConsent(false, null, null, null)`. |
| **Output** | `Future<void>` completes after native RPC validation and the synchronous SDK setter invocation. Validation or bridge failures throw `AppsFlyerException`; there is no native completion callback or request timeout. |

---

## Tests
`test/appsflyer_sdk_test.dart` covers both the mapping and the forward-only behavior:
- `setConsentData forwards all four consent fields to the native layer` asserts a fully populated GDPR call.
- `setConsentData forwards non-GDPR consent with null optional fields` asserts `isUserSubjectToGDPR: false` with the three optional fields sent as `null`.

---

## Known Limitations
- iOS requires `isUserSubjectToGDPR`; the three consent fields are optional at the RPC layer on both platforms. Incomplete GDPR consent is not rejected by the RPC bridge — native SDK behavior applies.
- Consent is order-sensitive relative to `start()` (it must be set before the first session to affect the launch request), but neither the Dart API nor either native handler enforces or warns about this ordering.
- "Every app start" means every cold/process start. The native SDK keeps the value for later background-to-foreground sessions in the same process; the Flutter plugin adds no persistence of its own.
- The native API has no completion callback, so a completed `Future` confirms only that the RPC layer accepted the call — not that the consent state reached AppsFlyer's servers.

---

## Dependencies
```mermaid
flowchart LR
    F012["F-012 · Manual GDPR/DMA Consent API"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
