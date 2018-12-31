import './main_page.dart';
import 'package:flutter/material.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

// void main() => runApp(myApp());

void main() {
  final Map options = {"afDevKey": "fdsgjkdfkg3435"};
  runApp(MyApp(appsFlyerOptions: options));
}

class MyApp extends StatelessWidget {
  AppsflyerSdk appsflyerSdk;

  MyApp({appsFlyerOptions}) {
    appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
    initSdk();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new MainPage(appsFlyerSdk: appsflyerSdk),
    );
  }

  Future<void> initSdk() {
    appsflyerSdk.initSdk().then((onValue) {
      print(onValue.toString());
    }).catchError((onError) {
      print(onError.toString());
    });
  }
}
