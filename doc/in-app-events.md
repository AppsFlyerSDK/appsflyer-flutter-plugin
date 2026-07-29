# In-app events & ad revenue

In-App Events provide insight on what is happening in your app. It is recommended to take the time and define the events you want to measure to allow you to measure ROI (Return on Investment) and LTV (Lifetime Value).

> **Audience:** apps sending custom in-app events or ad-revenue events. Requires the [core setup](getting-started.md).

Recording in-app events is performed by calling logEvent with event name and value parameters. See In-App Events documentation for more details.

**Note:** An In-App Event name must be no longer than 45 characters. Events names with more than 45 characters do not appear in the dashboard, but only in the raw Data, Pull and Push APIs.
Find more info about recording events [here](https://dev.appsflyer.com/hc/docs/in-app-events-sdk).

---

## logEvent

**<a id="logEvent"> `void logEvent(String eventName, Map? eventValues, {RequestSuccessListener? onSuccess, RequestErrorListener? onError})`**

| parameter    | type     | description                                   |
| -----------  |----------|------------------------------------------     |
| eventName    | String   | The event name, it is presented in your dashboard. |
| eventValues  | Map      | The event values that are sent with the event. |
| onSuccess    | `RequestSuccessListener?` | Optional. Invoked after the server accepts the event (HTTP 200). |
| onError      | `RequestErrorListener?`   | Optional. Invoked with `(int errorCode, String errorMessage)` when the request fails. |

`logEvent` returns `void`. Without a callback it is fire-and-forget; pass `onSuccess` / `onError` to observe the server request result (the native call then blocks until the request completes). See the [API reference](api-reference.md#logEvent) for details.

**Example:**
```dart
// Fire-and-forget.
appsflyerSdk.logEvent("purchase", {"af_revenue": 1.99, "af_currency": "USD"});

// Observe the result.
appsflyerSdk.logEvent(
  "purchase",
  {"af_revenue": 1.99, "af_currency": "USD"},
  onSuccess: () => print("logEvent success"),
  onError: (int code, String message) => print("logEvent error $code: $message"),
);
```

---

## Ad revenue

Log ad-revenue events with `logAdRevenue`, passing an `AdRevenueData` object. Always take
the `mediationNetwork` value from the `AFMediationNetwork` enum. `logAdRevenue` is
fire-and-forget (the native SDK has no completion callback), and an unknown mediation
network is dropped by the native bridge.

```dart
AdRevenueData adRevenueData = AdRevenueData(
  monetizationNetwork: "GoogleAdMob",
  mediationNetwork: AFMediationNetwork.applovinMax.value,
  currencyIso4217Code: "USD",
  revenue: 1.23,
  additionalParameters: {"adUnitId": "ca-app-pub-XXXX/YYYY"},
);

appsflyerSdk.logAdRevenue(adRevenueData);
```

See the [API reference](api-reference.md#logAdRevenue) for the full `AdRevenueData` /
`AFMediationNetwork` reference and the cross-platform mediation-network note.