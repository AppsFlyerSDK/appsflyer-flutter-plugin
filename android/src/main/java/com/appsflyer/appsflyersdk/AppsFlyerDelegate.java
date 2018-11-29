package com.appsflyer.appsflyersdk;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

import com.appsflyer.AFLogger;
import com.appsflyer.AppsFlyerConversionListener;
import com.appsflyer.AppsFlyerLib;
import com.appsflyer.AppsFlyerProperties;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Map;

class AppsFlyerDelegate{

    private final Activity activity;
    private final Context context;
    private final Application application;
    private MethodChannel.Result pendingResult;
    private MethodCall methodCall;
    private AppsFlyerLib instance;

    public AppsFlyerDelegate(Activity activity) {
        this.activity = activity;
        this.context = activity.getApplicationContext();
        this.application = activity.getApplication();
    }

    public void initSdk(MethodCall call, MethodChannel.Result result) {
        AppsFlyerConversionListener gcdListener = null;
        instance = AppsFlyerLib.getInstance();
        methodCall = call;
        pendingResult = result;

        String afDevKey = call.argument(AppsFlyerConstants.AF_DEV_KEY);

        Log.d("FlutterSdk", "Call");
        Log.d("FlutterSdk", "Dev key: " + afDevKey);
        Log.d("FlutterSdk", context.toString());

        gcdListener = registerConversionListener(instance);

        instance.setLogLevel(AFLogger.LogLevel.VERBOSE);
        instance.init(afDevKey, gcdListener, context);
        instance.trackEvent(context, null, null);
        instance.startTracking(application);
    }

    private AppsFlyerConversionListener registerConversionListener(AppsFlyerLib instance){
        return new AppsFlyerConversionListener() {
            @Override
            public void onInstallConversionDataLoaded(Map<String, String> map) {
                Log.d("AppsFlyerGCD", map.toString());
                finishWithSuccess(map);
            }

            @Override
            public void onInstallConversionFailure(String s) {
                Log.d("AppsFlyerGCD", s);

            }

            @Override
            public void onAppOpenAttribution(Map<String, String> map) {
                Log.d("AppsFlyerGCD", map.toString());
            }

            @Override
            public void onAttributionFailure(String s) {
                Log.d("AppsFlyerGCD", s);
            }
        };
    }

    private void finishWithSuccess(Map<String, String> data) {
        pendingResult.success(data);
        clearMethodCallAndResult();
    }

    private void finishWithError(String errorCode, String errorMessage, Throwable throwable) {
        pendingResult.error(errorCode, errorMessage, throwable);
        clearMethodCallAndResult();
    }

    private void clearMethodCallAndResult() {
        methodCall = null;
        pendingResult = null;
    }

    public void trackEvent(MethodCall call, MethodChannel.Result result) {
        //Take the parameters from the method call
        String eventName;
        Map<String, Object> eventValues = null;

        eventName = call.argument(AppsFlyerConstants.AF_EVENT_NAME);
        JSONObject eventVals = call.arguments(AppsFlyerConstants.AF_EVENT_VALUES);

        //Send event data through appsflyer sdk
        instance.trackEvent(context, eventName, eventValues);
    }
}
