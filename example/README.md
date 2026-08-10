# appsflyer_sdk_example

This plugin includes a demo project. To run it, clone the
`appsflyer-flutter-plugin` repository and execute the following from the
repository root:

Create `example/.env` with your AppsFlyer credentials:

```dotenv
DEV_KEY=YOUR_DEV_KEY
APP_ID=YOUR_IOS_APP_ID
```

`APP_ID` is required for iOS. For an Android-only run, its value may be empty,
but the key must still be present because the example loads it from `.env`.

```bash
cd example
flutter pub get
flutter run
```

![demo printscreen](assets/demo_example.png?raw=true)
