package com.appsflyer.appsflyersdk;

import android.app.Application;
import android.content.Context;

import com.appsflyer.AFLogger;
import com.appsflyer.AppsFlyerConversionListener;
import com.appsflyer.AppsFlyerLib;

import org.json.JSONException;
import org.json.JSONObject;

import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterView;

import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_FAILURE;
import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_ON_APP_OPEN_ATTRIBUTION;
import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_ON_ATTRIBUTION_FAILURE;
import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_ON_INSTALL_CONVERSION_DATA_LOADED;
import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_ON_INSTALL_CONVERSION_FAILURE;
import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_SUCCESS;

/**
 * AppsflyerSdkPlugin
 */
public class AppsflyerSdkPlugin implements MethodCallHandler {
    /**
     * Plugin registration.
     */
    private FlutterView mFlutterVliew;
    private Context mContext;
    private Application mApplication;

    private static AppsflyerSdkPlugin instance = null;

    AppsflyerSdkPlugin(Registrar registrar) {
        this.mFlutterVliew = registrar.view();
        this.mContext = registrar.activity().getApplicationContext();
        this.mApplication = registrar.activity().getApplication();
    }

    public static void registerWith(Registrar registrar) {

        if (instance == null) {
            instance = new AppsflyerSdkPlugin(registrar);
        }

        final MethodChannel channel = new MethodChannel(registrar.messenger(), AppsFlyerConstants.AF_METHOD_CHANNEL);

        channel.setMethodCallHandler(instance);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        final String method = call.method;
        switch (method) {
        case "initSdk":
            initSdk(call, result);
            break;
        case "trackEvent":
            trackEvent(call, result);
            break;
        default:
            result.notImplemented();
            break;
        }
    }

    private void initSdk(MethodCall call, MethodChannel.Result result) {
        AppsFlyerConversionListener gcdListener = null;
        AppsFlyerLib instance = AppsFlyerLib.getInstance();

        String afDevKey = call.argument(AppsFlyerConstants.AF_DEV_KEY);

        boolean getGCD = call.argument(AppsFlyerConstants.AF_GCD);

        if (getGCD) {
            gcdListener = registerConversionListener(instance);
        }

        boolean isDebug = call.argument(AppsFlyerConstants.AF_IS_DEBUG);
        if (isDebug) {
            instance.setLogLevel(AFLogger.LogLevel.DEBUG);
            instance.setDebugLog(true);
        } else {
            instance.setDebugLog(false);
        }

        instance.init(afDevKey, gcdListener, mContext);
        instance.trackEvent(mContext, null, null);
        instance.startTracking(mApplication);

        final Map<String, String> response = new HashMap<>();
        response.put("status", "OK");

        result.success(response);
    }

    private void trackEvent(MethodCall call, MethodChannel.Result result) {

        AppsFlyerLib instance = AppsFlyerLib.getInstance();

        final String eventName = call.argument(AppsFlyerConstants.AF_EVENT_NAME);
        final Map<String, Object> eventValues = call.argument(AppsFlyerConstants.AF_EVENT_VALUES);

        // Send event data through appsflyer sdk
        instance.trackEvent(mContext, eventName, eventValues);

        result.success(true);
    }

    private AppsFlyerConversionListener registerConversionListener(AppsFlyerLib instance) {
        return new AppsFlyerConversionListener() {
            @Override
            public void onInstallConversionDataLoaded(Map<String, String> map) {
                handleSuccess(AF_ON_INSTALL_CONVERSION_DATA_LOADED, map);
            }

            @Override
            public void onInstallConversionFailure(String errorMessage) {
                handleError(AF_ON_INSTALL_CONVERSION_FAILURE, errorMessage);
            }

            @Override
            public void onAppOpenAttribution(Map<String, String> map) {
                handleSuccess(AF_ON_APP_OPEN_ATTRIBUTION, map);
            }

            @Override
            public void onAttributionFailure(String errorMessage) {
                handleError(AF_ON_ATTRIBUTION_FAILURE, errorMessage);
            }
        };
    }

    private void handleSuccess(String eventType, Map<String, String> data) {
        try {
            JSONObject obj = new JSONObject();

            obj.put("status", AF_SUCCESS);
            obj.put("type", eventType);
            obj.put("data", new JSONObject(data));

            sendEventToDart(obj);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void handleError(String eventType, String errorMessage) {

        try {
            JSONObject obj = new JSONObject();

            obj.put("status", AF_FAILURE);
            obj.put("type", eventType);
            obj.put("data", errorMessage);

            sendEventToDart(obj);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void sendEventToDart(final JSONObject params) {

        byte[] bytes = params.toString().getBytes();

        ByteBuffer message = ByteBuffer.allocateDirect(bytes.length);
        message.put(bytes);

        mFlutterVliew.send(AppsFlyerConstants.AF_EVENTS_CHANNEL, message, new BinaryMessenger.BinaryReply() {
            @Override
            public void reply(ByteBuffer byteBuffer) {
                //
            }
        });
    }
}
