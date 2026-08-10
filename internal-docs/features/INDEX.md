# AppsFlyer Flutter Plugin — Feature Catalog Index

69 catalogued features across 6 categories. Seven are `removed` in SDK 7 (F-008, F-021, F-023, F-036, F-038, F-056, F-058) — kept as tombstone entries pointing to the current API or migration documentation. See `DIAGRAM.md` for runtime/init dependency diagrams and the verified dependency table.

> **Verification status:** Every entry was checked on **2026-08-10** against the current Dart API, platform plugin sources, pinned Android/iOS RPC implementations, relevant native SDK behavior, and available tests. `last_verified` records an implementation audit, not proof of end-to-end device behavior; each feature's Tests and Known Limitations sections identify remaining coverage gaps.

---

## sdkCore

SDK lifecycle, identity, privacy/consent, and low-level configuration.

| ID | Name | Status | Platform |
|----|------|--------|----------|
| F-001 | SDK Initialization | active | both |
| F-002 | SDK Start (session launch) | active | both |
| F-003 | SDK/Plugin Version Retrieval | active | both |
| F-006 | Custom Host Configuration | active | both |
| F-007 | Android ID Collection Opt-out | active | android |
| F-008 | Manual IMEI/Android ID Override | removed | android |
| F-009 | Minimum Time Between Sessions | active | both |
| F-011 | TCF/DMA Automatic Consent Collection | active | both |
| F-012 | Manual GDPR/DMA Consent API | active | both |
| F-013 | User Anonymization (Opt-out logging) | active | both |
| F-015 | Customer User ID (CUID) | active | both |
| F-016 | Update vs. Fresh-Install Flag | active | android |
| F-017 | SDK Kill Switch (stop) | active | both |
| F-018 | Uninstall Measurement | active | both |
| F-019 | User PII Collection and Clearing | active | both |
| F-020 | AppsFlyer UID Retrieval | active | both |
| F-021 | Delayed Session Start Pending CUID | removed | android |
| F-034 | Advertising Identifier Collection Disable | active | both |
| F-046 | Disable Network Data Transfer | active | android |
| F-047 | AppSet ID Collection Opt-out (Android) | active | android |
| F-048 | Plugin Metadata Reporting to Native SDK | active | both |
| F-057 | ASA (Apple Search Ads) Collection Opt-out | active | ios |
| F-058 | ATT Authorization Wait Timeout (iOS) | removed | ios |
| F-059 | Debug Logging Toggle | active | both |
| F-060 | Swift Package Manager (SPM) Support (Core, iOS) | active | ios |
| F-062 | Android Manual Session Logging | active | android |
| F-063 | Custom Install ID | active | both |
| F-066 | iOS Device Data Collection Controls | active | ios |

## eventsAndRevenue

Reporting in-app events, ad revenue, and monetary context back to AppsFlyer.

| ID | Name | Status | Platform |
|----|------|--------|----------|
| F-004 | In-App Event Logging | active | both |
| F-005 | Ad Revenue Logging | active | both |
| F-010 | Currency Code Setting | active | both |
| F-026 | Additional Custom Data | active | both |
| F-061 | Manual Location Logging | active | both |

## purchaseValidation

Server-side validation of purchases/subscriptions — legacy API and the Purchase Connector.

| ID | Name | Status | Platform |
|----|------|--------|----------|
| F-023 | In-App Purchase Validation V1 (Android/iOS separate APIs) | removed | both |
| F-024 | In-App Purchase Validation V2 (cross-platform) | active | both |
| F-025 | iOS Receipt Validation Sandbox Toggle | active | ios |
| F-038 | Legacy Purchase-Validation Notification Callback | removed | both |
| F-049 | Purchase Connector: Configuration & Lifecycle | active | both |
| F-050 | Purchase Connector: StoreKit Version Selection (iOS) | active | ios |
| F-051 | Purchase Connector: Android Validation Result Listeners | active | android |
| F-052 | Purchase Connector: iOS Combined Validation Callback | active | ios |
| F-053 | Purchase Connector: Google Play Purchase/Subscription Data Models | active | android |
| F-054 | Purchase Connector: Build-Time Opt-in | active | both |
| F-055 | Missing-Configuration Guard for Purchase Connector | active | both |

## deepLinking

Resolving, forwarding, and delivering deep-link/attribution results across platform entry points.

| ID | Name | Status | Platform |
|----|------|--------|----------|
| F-014 | Manual Deep-Link Re-trigger (performDeepLinking) | active | both |
| F-022 | Push Notification Deep-Link Path Config | active | both |
| F-031 | Push Notification Data Handling | active | both |
| F-032 | Facebook Deferred App Links | active | both |
| F-035 | Conversion Data Callback (GCD) | active | both |
| F-036 | App-Open Attribution Callback (OAOA) | removed | both |
| F-037 | Unified Deep Linking (UDL) Callback & Models | active | both |
| F-039 | Native iOS Deep-Link Entry Points (URL scheme / Universal Links / Scenes) | active | ios |
| F-040 | Android New-Intent Deep-Link Forwarding | active | android |
| F-045 | Deep-Link URL Resolution Allow-list | active | both |
| F-067 | Deep-Link Resolution Timeout | active | both |
| F-068 | Deep-Link URL Parameter Appending | active | both |

## oneLinkAndGrowth

OneLink-based invite/referral link generation and cross-app promotion.

| ID | Name | Status | Platform |
|----|------|--------|----------|
| F-027 | User Invite Link Generation (OneLink) | active | both |
| F-028 | App Invite OneLink ID Configuration | active | both |
| F-029 | Cross-Promotion Impression/Click Tracking | active | both |
| F-030 | Custom/Branded OneLink Domains | active | both |
| F-056 | App Invite OneLink ID (init-time option) | removed | both |

## platformIntegration

Partner-ecosystem hooks and platform-specific attribution quirks.

| ID | Name | Status | Platform |
|----|------|--------|----------|
| F-033 | SKAdNetwork Opt-out (iOS) | active | ios |
| F-041 | Current Device Language Override | active | ios |
| F-042 | Partner Postback Sharing Filter | active | both |
| F-043 | Out-of-Store Install Source (Android) | active | android |
| F-044 | Partner-Specific Data | active | both |
| F-064 | Android Preinstall Attribution and Detection | active | android |
| F-065 | Android App ID Override | active | android |
| F-069 | Android Facebook Attribution ID Retrieval | active | android |
