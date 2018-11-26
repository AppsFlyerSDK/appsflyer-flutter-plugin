package com.appsflyer.appsflyersdk;

import android.app.Application;
import android.content.Context;
import android.util.Log;

import com.appsflyer.AFLogger;
import com.appsflyer.AppsFlyerLib;
import com.appsflyer.AppsFlyerProperties;

import java.util.logging.Level;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** AppsflyerSdkPlugin */
public class AppsflyerSdkPlugin implements MethodCallHandler {
  /** Plugin registration. */
  private static Context context;
  private static Application application;

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "appsflyer_sdk");
    channel.setMethodCallHandler(new AppsflyerSdkPlugin());
    context = registrar.context();
    application = registrar.activity().getApplication();
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("initSdk")) {
      Log.d("FlutterSdk","Call");
      String afDevKey = call.argument("afDevKey");
      Log.d("FlutterSdk","Dev key: "+afDevKey);
      Log.d("FlutterSdk",context.toString());
      AppsFlyerLib.getInstance().setLogLevel(AFLogger.LogLevel.VERBOSE);
      AppsFlyerLib.getInstance().init(afDevKey,null, context);
      AppsFlyerLib.getInstance().trackEvent(context, null, null);
      AppsFlyerLib.getInstance().startTracking(application);
//      result.success("Android initSdk");
    } else {
//      result.notImplemented();
    }
  }
}
