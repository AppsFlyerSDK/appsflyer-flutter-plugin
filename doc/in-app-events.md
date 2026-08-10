# In-app events & ad revenue

In-App Events provide insight on what is happening in your app. It is recommended to take the time and define the events you want to measure to allow you to measure ROI (Return on Investment) and LTV (Lifetime Value).

> **Audience:** apps sending custom in-app events or ad-revenue events. Requires the [core setup](getting-started.md).

Recording in-app events is performed by calling logEvent with event name and value parameters. See In-App Events documentation for more details.

**Note:** An In-App Event name must not be empty. Custom event names should be no longer than 100 characters.
Find more info about recording events [here](https://dev.appsflyer.com/hc/docs/in-app-events-sdk).

---

## logEvent

**<a id="logEvent"> `Future<void> logEvent(String eventName, {Map<String, dynamic>? eventValues, bool awaitResponse = false})`**

| parameter    | type     | description                                   |
| -----------  |----------|------------------------------------------     |
| eventName    | String   | The event name, it is presented in your dashboard. |
| eventValues  | `Map<String, dynamic>?` | Optional named event parameters sent with the event. |
| awaitResponse | `bool` | Optional named parameter. Defaults to `false`. When `true`, wait for the native request callback. When `false`, return after the native SDK accepts the call. |

When `awaitResponse` is `true`, the Future completes after the native
request callback succeeds. Request failures and timeouts are reported as
`AppsFlyerException`. See the [API reference](api-reference.md#logEvent) for
details.
With the default `false`, it completes when the native SDK accepts the
fire-and-forget call and does not report the native delivery result.

**Example:**
```dart
try {
  await appsflyerSdk.logEvent(
    "purchase",
    eventValues: {"af_revenue": 1.99, "af_currency": "USD"},
    awaitResponse: true,
  );
  print("logEvent success");
} on AppsFlyerException catch (error) {
  print("logEvent error: $error");
}
```

---

## Ad revenue

Log ad-revenue events with `logAdRevenue`. Always take the `mediationNetwork`
value from the `AFMediationNetwork` enum. The returned Future completes after
the plugin validates the request and invokes the native logging API. Validation
and native call failures are reported as `AppsFlyerException`. The native API
has no delivery callback, so completion does not confirm that the event was
uploaded.

```dart
Future<void> logAdRevenue({
  required String monetizationNetwork,
  required AFMediationNetwork mediationNetwork,
  required String currencyIso4217Code,
  required double revenue,
  Map<String, dynamic>? additionalParameters,
})
```

| parameter | type | description |
| --------- | ---- | ----------- |
| monetizationNetwork | String | The monetization network that generated the revenue. |
| mediationNetwork | `AFMediationNetwork` | The mediation platform managing the ad. |
| currencyIso4217Code | String | A three-letter ISO 4217 currency code, such as `USD`. |
| revenue | double | The ad-revenue amount. |
| additionalParameters | `Map<String, dynamic>?` | Optional additional values for the ad-revenue event. |

```dart
await appsflyerSdk.logAdRevenue(
  monetizationNetwork: "GoogleAdMob",
  mediationNetwork: AFMediationNetwork.applovinMax,
  currencyIso4217Code: "USD",
  revenue: 1.23,
  additionalParameters: {"adUnitId": "ca-app-pub-XXXX/YYYY"},
);
```

See the [API reference](api-reference.md#logAdRevenue) for the full
`AFMediationNetwork` reference and the cross-platform mediation-network note.
