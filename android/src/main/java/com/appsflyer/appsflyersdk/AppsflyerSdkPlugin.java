package com.appsflyer.appsflyersdk;

import android.app.Application;
import android.content.Context;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** AppsflyerSdkPlugin */
public class AppsflyerSdkPlugin implements MethodCallHandler {
  /** Plugin registration. */
  private final AppsFlyerDelegate delegate;
  private final Registrar registrar;

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "appsflyer_sdk");
    final AppsFlyerDelegate delegate = new AppsFlyerDelegate(registrar.activity());

    channel.setMethodCallHandler(new AppsflyerSdkPlugin(registrar, delegate));
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    String method = call.method;
    switch (method) {
    case "initSdk":
      delegate.initSdk(call, result);
      break;
    case "trackEvent":
      delegate.trackEvent(call, result);
      break;
    default:
      result.notImplemented();
      break;
    }
  }

  AppsflyerSdkPlugin(Registrar registrar, AppsFlyerDelegate delegate) {
    this.registrar = registrar;
    this.delegate = delegate;
  }
}
