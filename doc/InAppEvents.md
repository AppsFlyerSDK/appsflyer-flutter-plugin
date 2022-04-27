# In-App events

In-App Events provide insight on what is happening in your app. It is recommended to take the time and define the events you want to measure to allow you to measure ROI (Return on Investment) and LTV (Lifetime Value).

Recording in-app events is performed by calling logEvent with event name and value parameters. See In-App Events documentation for more details.

**Note:** An In-App Event name must be no longer than 45 characters. Events names with more than 45 characters do not appear in the dashboard, but only in the raw Data, Pull and Push APIs.
Find more info about recording events [here](https://dev.appsflyer.com/hc/docs/in-app-events-sdk).

---

## logEvent

**<a id="logEvent"> `logEvent(String eventName, Map? eventValues)`**

| parameter    | type     | description                                   |
| -----------  |----------|------------------------------------------     |
| eventName    | String   | The event name, it is presented in your dashboard. |
| eventValues  | Map     | The event values that are sent with the event. |

**Example:**
```dart
Future<bool?> logEvent(String eventName, Map? eventValues) async {
    bool? result;
    try {
        result = await appsflyerSdk.logEvent(eventName, eventValues);
    } on Exception catch (e) {}
    print("Result logEvent: $result");
}
```