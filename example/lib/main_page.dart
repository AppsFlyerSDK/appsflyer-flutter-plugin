import 'dart:async';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
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
  Map<String, dynamic> _deepLinkData;
  Map<String, dynamic> _gcd;

  // called on every foreground
  @override
  void initState() {
    super.initState();
    final dotEnv = DotEnv();
    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: dotEnv.env["DEV_KEY"],
      appId: dotEnv.env["APP_ID"],
      showDebug: kDebugMode,
    );

    _appsflyerSdk = AppsflyerSdk(options)
      ..onAppOpenAttribution(_handleAppOpenAttribution)
      ..onInstallConversionData(_handleInstallConversionData)
      ..onDeepLinking(_handleDeepLinking);
  }

  void _handleDeepLinking(AppsFlyerResponse response) {
    print('res: $response');
    setState(() {
      _deepLinkData = response.then((data) {
        return data;
      });
    });
  }

  void _handleInstallConversionData(AppsFlyerResponse response) {
    print('res: $response');
    setState(() {
      _gcd = response.then((data) {
        return data;
      });
    });
  }

  void _handleAppOpenAttribution(AppsFlyerResponse response) {
    print('res: $response');
    setState(() {
      _deepLinkData = response.then((data) {
        return data;
      });
    });
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
                },
              ),
            ],
          ),
        ),
        body: FutureBuilder<dynamic>(
            future: _appsflyerSdk.initSdk(
              registerConversionDataCallback: true,
              registerOnAppOpenAttributionCallback: true,
              registerOnDeepLinkingCallback: true,
            ),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else {
                if (snapshot.hasData) {
                  return HomeContainer(
                    onData: _gcd,
                    deepLinkData: _deepLinkData,
                    logEvent: logEvent,
                  );
                } else {
                  return Center(child: Text("Error initializing sdk"));
                }
              }
            }));
  }

  Future<bool> logEvent(String eventName, Map<String, dynamic> eventValues) {
    return _appsflyerSdk.logEvent(eventName, eventValues);
  }
}
