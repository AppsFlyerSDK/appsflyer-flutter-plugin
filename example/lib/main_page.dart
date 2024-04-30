import 'dart:async';
import 'dart:io';
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
  late AppsflyerSdk _appsflyerSdk;
  Map _deepLinkData = {};
  Map _gcd = {};

  @override
  void initState() {
    super.initState();
    afStart();
  }

  void afStart() async {
    // SDK Options
    final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: dotenv.env["DEV_KEY"]!,
        appId: dotenv.env["APP_ID"]!,
        showDebug: true,
        timeToWaitForATTUserAuthorization: 15,
        manualStart: true);
    /*
    final Map? map = {
      'afDevKey': dotenv.env["DEV_KEY"]!,
      'appId': dotenv.env["APP_ID"]!,
      'isDebug': true,
      'timeToWaitForATTUserAuthorization': 15.0//,
      //'manualStart': false
    };
    _appsflyerSdk = AppsflyerSdk(map);
     */
    _appsflyerSdk = AppsflyerSdk(options);

    /*
    Setting configuration to the SDK:
    _appsflyerSdk.setCurrencyCode("USD");
    _appsflyerSdk.enableTCFDataCollection(true);
    var forGdpr = AppsFlyerConsent.forGDPRUser(hasConsentForDataUsage: true, hasConsentForAdsPersonalization: true);
    _appsflyerSdk.setConsentData(forGdpr);
    var nonGdpr = AppsFlyerConsent.nonGDPRUser();
    _appsflyerSdk.setConsentData(nonGdpr);
     */

    // Init of AppsFlyer SDK
    await _appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true);

    // Conversion data callback
    _appsflyerSdk.onInstallConversionData((res) {
      print("onInstallConversionData res: " + res.toString());
      setState(() {
        _gcd = res;
      });
    });

    // App open attribution callback
    _appsflyerSdk.onAppOpenAttribution((res) {
      print("onAppOpenAttribution res: " + res.toString());
      setState(() {
        _deepLinkData = res;
      });
    });

    // Deep linking callback
    _appsflyerSdk.onDeepLinking((DeepLinkResult dp) {
      switch (dp.status) {
        case Status.FOUND:
          print(dp.deepLink?.toString());
          print("deep link value: ${dp.deepLink?.deepLinkValue}");
          break;
        case Status.NOT_FOUND:
          print("deep link not found");
          break;
        case Status.ERROR:
          print("deep link error: ${dp.error}");
          break;
        case Status.PARSE_ERROR:
          print("deep link status parsing error");
          break;
      }
      print("onDeepLinking res: " + dp.toString());
      setState(() {
        _deepLinkData = dp.toJson();
      });
    });

    //_appsflyerSdk.anonymizeUser(true);
    if (Platform.isAndroid) {
      _appsflyerSdk.performOnDeepLinking();
    }
    setState(() {}); // Call setState to rebuild the widget
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AppsFlyer SDK example app'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Builder(
        builder: (context) {
          return SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: HomeContainer(
                    onData: _gcd,
                    deepLinkData: _deepLinkData,
                    logEvent: logEvent,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _appsflyerSdk.startSDK(
                      onSuccess: () {
                        showMessage("AppsFlyer SDK initialized successfully.");
                      },
                      onError: (int errorCode, String errorMessage) {
                        showMessage("Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage");
                      },
                    );
                  },
                  child: Text("START SDK"),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool?> logEvent(String eventName, Map eventValues) async {
    bool? logResult;
    try {
      logResult = await _appsflyerSdk.logEvent(eventName, eventValues);
      print("Event logged");
    } catch (e) {
      print("Failed to log event: $e");
    }
    return logResult;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
      content:
      Text(message),
    ));
  }
}


