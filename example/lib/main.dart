import './main_page.dart';
import 'package:flutter/material.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

void main() {
  final AppsFlyerOptions options = AppsFlyerOptions(afDevKey: "fdf");
  print("++++++++++++++DEV KEY++++++++++++" + options.afDevKey);
  print("++++++++++++++APP ID+++++++++++++" + options.appId);
  runApp(MyApp(appsFlyerOptions: options));
}

class MyApp extends StatelessWidget {
  AppsflyerSdk appsflyerSdk;

  MyApp({appsFlyerOptions}) {
    appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new MainPage(appsFlyerSdk: appsflyerSdk, initSdk: initSdk),
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
