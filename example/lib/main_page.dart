import 'dart:async';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'home_container.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  AppsflyerSdk _appsflyerSdk;

  @override
  void initState() {
    super.initState();
    final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: DotEnv().env["DEV_KEY"],
        appId: DotEnv().env["APP_ID"],
        showDebug: true);
    _appsflyerSdk = AppsflyerSdk(options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Column(
            children: <Widget>[
              Text('AppsFlyer SDK example app'),
              FutureBuilder<String>(
                  future: _appsflyerSdk.getSDKVersion(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    return Text(snapshot.hasData ? snapshot.data : "");
                  })
            ],
          ),
        ),
        body: FutureBuilder<dynamic>(
            future: _appsflyerSdk.initSdk(
                registerConversionDataCallback: true,
                registerOnAppOpenAttributionCallback: true),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else {
                if (snapshot.hasData) {
                  return HomeContainer(
                    onData: _appsflyerSdk.conversionDataStream,
                    onAttribution: _appsflyerSdk.appOpenAttributionStream,
                    trackEvent: logEvent,
                  );
                } else {
                  return Center(child: Text("Error initializing sdk"));
                }
              }
            }));
  }

  Future<bool> logEvent(String eventName, Map eventValues) {
    return _appsflyerSdk.logEvent(eventName, eventValues);
  }
}
