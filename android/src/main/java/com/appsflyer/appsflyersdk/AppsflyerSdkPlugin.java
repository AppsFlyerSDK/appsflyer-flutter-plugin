package com.appsflyer.appsflyersdk;

import android.app.Activity;
import android.app.Application;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import com.appsflyer.AFLogger;
import com.appsflyer.AppsFlyerConversionListener;
import com.appsflyer.AppsFlyerInAppPurchaseValidatorListener;
import com.appsflyer.AppsFlyerLib;
import com.appsflyer.AppsFlyerProperties;
import com.appsflyer.AppsFlyerTrackingRequestListener;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterView;

import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_EVENTS_CHANNEL;
import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_FAILURE;
import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_ON_APP_OPEN_ATTRIBUTION;
import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_ON_INSTALL_CONVERSION_DATA_LOADED;
import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_SUCCESS;
import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_VALIDATE_PURCHASE;

/**
 * AppsflyerSdkPlugin
 */
public class AppsflyerSdkPlugin implements MethodCallHandler, FlutterPlugin, ActivityAware {
    private  EventChannel mEventChannel;
    /**
     * Plugin registration.
     */
    //private FlutterView mFlutterView;
    private Context mContext;
    private Application mApplication;
    private Intent mIntent;
    private MethodChannel mMethodChannel;

    private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
        this.mContext = applicationContext;
        this.mEventChannel = new EventChannel(messenger, AF_EVENTS_CHANNEL);
        mEventChannel.setStreamHandler(new AppsFlyerStreamHandler(mContext));
        mMethodChannel = new MethodChannel(messenger, AppsFlyerConstants.AF_METHOD_CHANNEL);
        mMethodChannel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        final String method = call.method;
        switch (method) {
            case "initSdk":
                initSdk(call, result);
                break;
            case "logEvent":
                logEvent(call, result);
                break;
            case "setHost":
                setHost(call, result);
                break;
            case "setCurrencyCode":
                setCurrencyCode(call, result);
                break;
            case "setIsUpdate":
                setIsUpdate(call, result);
                break;
            case "stop":
                stop(call, result);
                break;
            case "updateServerUninstallToken":
                updateServerUninstallToken(call, result);
                break;
            case "setImeiData":
                setImeiData(call, result);
                break;
            case "setAndroidIdData":
                setAndroidIdData(call, result);
                break;
            case "enableLocationCollection":
                enableLocationCollection(call, result);
                break;
            case "setCustomerUserId":
                setCustomerUserId(call, result);
                break;
            case "waitForCustomerUserId":
                waitForCustomerUserId(call, result);
                break;
            case "setAdditionalData":
                setAdditionalData(call, result);
                break;
            case "setUserEmails":
                setUserEmails(call, result);
                break;
            case "setUserEmailsWithCryptType":
                setUserEmailsWithCryptType(call, result);
                break;
            case "setCollectAndroidId":
                setCollectAndroidId(call, result);
                break;
            case "setCollectIMEI":
                setCollectIMEI(call, result);
                break;
            case "getHostName":
                getHostName(result);
                break;
            case "getHostPrefix":
                getHostPrefix(result);
                break;
            case "setMinTimeBetweenSessions":
                setMinTimeBetweenSessions(call, result);
                break;
            case "validateAndLogInAppPurchase":
                validateAndLogInAppPurchase(call, result);
                break;
            case "getAppsFlyerUID":
                getAppsFlyerUID(result);
                break;
            case "getSDKVersion":
                getSdkVersion(result);
                break;
            case "setSharingFilter":
                setSharingFilter(call, result);
                break;
            case "setSharingFilterForAllPartners":
                setSharingFilterForAllPartners(result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void setSharingFilterForAllPartners(Result result) {
        AppsFlyerLib.getInstance().setSharingFilterForAllPartners();
        result.success(null);
    }

    private void setSharingFilter(MethodCall call, Result result) {
        AppsFlyerLib.getInstance().setSharingFilter();
        result.success(null);
    }

    private void getAppsFlyerUID(Result result) {
        result.success(AppsFlyerLib.getInstance().getAppsFlyerUID(this.mContext));
    }

    private void setUserEmailsWithCryptType(MethodCall call, Result result) {
        List<String> emails = call.argument("emails");
        int cryptTypeInt = call.argument("cryptType");
        AppsFlyerProperties.EmailsCryptType cryptType = AppsFlyerProperties.EmailsCryptType.values()[cryptTypeInt];
        if (emails != null) {
            AppsFlyerLib.getInstance().setUserEmails(cryptType, emails.toArray(new String[0]));
        }
    }

    private void validateAndLogInAppPurchase(MethodCall call, Result result) {
        registerValidatorListener();
        String publicKey = (String) call.argument("publicKey");
        String signature = (String) call.argument("signature");
        String purchaseData = (String) call.argument("purchaseData");
        String price = (String) call.argument("price");
        String currency = (String) call.argument("currency");
        Map<String, String> additionalParameters = (Map<String, String>) call.argument("additionalParameters");
        AppsFlyerLib.getInstance().validateAndTrackInAppPurchase(mContext, publicKey, signature, purchaseData, price,
                currency, additionalParameters);
        result.success(null);
    }

    private void registerValidatorListener() {
        AppsFlyerInAppPurchaseValidatorListener validatorListener = new AppsFlyerInAppPurchaseValidatorListener() {
            @Override
            public void onValidateInApp() {
                JSONObject obj = new JSONObject();

                try {
                    obj.put("status", AF_SUCCESS);
                    obj.put("type", AF_VALIDATE_PURCHASE);
                    sendEventToDart(obj, AF_EVENTS_CHANNEL);
                } catch (JSONException e) {
                    e.printStackTrace();
                }

            }

            @Override
            public void onValidateInAppFailure(String s) {
                JSONObject obj = new JSONObject();
                try {
                    obj.put("status", AF_FAILURE);
                    obj.put("type", AF_VALIDATE_PURCHASE);
                    obj.put("error", s);
                    sendEventToDart(obj, AF_EVENTS_CHANNEL);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        };
        AppsFlyerLib.getInstance().registerValidatorListener(mContext, validatorListener);
    }

    private void setMinTimeBetweenSessions(MethodCall call, Result result) {
        int seconds = (int) call.argument("seconds");
        AppsFlyerLib.getInstance().setMinTimeBetweenSessions(seconds);
        result.success(null);
    }

    private void getHostPrefix(Result result) {
        result.success(AppsFlyerLib.getInstance().getHostPrefix());
    }

    private void getSdkVersion(Result result) {
        result.success(AppsFlyerLib.getInstance().getSdkVersion());
    }

    private void getHostName(Result result) {
        result.success(AppsFlyerLib.getInstance().getHostName());
    }

    private void setCollectIMEI(MethodCall call, Result result) {
        boolean isCollect = (boolean) call.argument("isCollect");
        AppsFlyerLib.getInstance().setCollectIMEI(isCollect);
        result.success(null);
    }

    private void setCollectAndroidId(MethodCall call, Result result) {
        boolean isCollect = (boolean) call.argument("isCollect");
        AppsFlyerLib.getInstance().setCollectAndroidID(isCollect);
        result.success(null);
    }

    private void waitForCustomerUserId(MethodCall call, Result result) {
        boolean wait = (boolean) call.argument("wait");
        AppsFlyerLib.getInstance().waitForCustomerUserId(wait);
        result.success(null);
    }

    private void setAdditionalData(MethodCall call, Result result) {
        HashMap<String, Object> customData = (HashMap<String, Object>) call.argument("customData");
        AppsFlyerLib.getInstance().setAdditionalData(customData);
        result.success(null);
    }

    private void setUserEmails(MethodCall call, Result result) {
        List<String> userEmails = call.argument("emails");
        if (userEmails != null) {
            AppsFlyerLib.getInstance().setUserEmails(userEmails.toArray(new String[0]));
        }
        result.success(null);
    }

    private void setCustomerUserId(MethodCall call, Result result) {
        String userId = (String) call.argument("id");
        AppsFlyerLib.getInstance().setCustomerUserId(userId);
        result.success(null);
    }

    private void enableLocationCollection(MethodCall call, Result result) {
        boolean flag = (boolean) call.argument("flag");
        AppsFlyerLib.getInstance().enableLocationCollection(flag);
        result.success(null);
    }

    private void setAndroidIdData(MethodCall call, Result result) {
        String androidId = (String) call.argument("androidId");
        AppsFlyerLib.getInstance().setAndroidIdData(androidId);
        result.success(null);
    }

    private void setImeiData(MethodCall call, Result result) {
        String imei = (String) call.argument("imei");
        AppsFlyerLib.getInstance().setImeiData(imei);
        result.success(null);
    }

    private void updateServerUninstallToken(MethodCall call, Result result) {
        String token = (String) call.argument("token");
        AppsFlyerLib.getInstance().updateServerUninstallToken(mContext, token);
        result.success(null);
    }

    private void stop(MethodCall call, Result result) {
        boolean isTrackingStopped = (boolean) call.argument("isTrackingStopped");
        AppsFlyerLib.getInstance().stopTracking(isTrackingStopped, mContext);
        result.success(null);
    }

    private void setIsUpdate(MethodCall call, Result result) {
        boolean isUpdate = (boolean) call.argument("isUpdate");
        AppsFlyerLib.getInstance().setIsUpdate(isUpdate);
        result.success(null);
    }

    private void setCurrencyCode(MethodCall call, Result result) {
        String currencyCode = (String) call.argument("currencyCode");
        AppsFlyerLib.getInstance().setCurrencyCode(currencyCode);
        result.success(null);
    }

    private void setHost(MethodCall call, MethodChannel.Result result) {
        String hostPrefix = call.argument(AppsFlyerConstants.AF_HOST_PREFIX);
        String hostName = call.argument(AppsFlyerConstants.AF_HOST_NAME);

        AppsFlyerLib.getInstance().setHost(hostPrefix, hostName);
    }

    private void initSdk(MethodCall call, final MethodChannel.Result result) {
        AppsFlyerConversionListener gcdListener = null;
        AppsFlyerLib instance = AppsFlyerLib.getInstance();

        if (mIntent.getData() != null) {
            instance.setPluginDeepLinkData(mIntent);
        }

        String afDevKey = (String) call.argument(AppsFlyerConstants.AF_DEV_KEY);
        if(afDevKey == null || afDevKey.equals("")){
            result.error(null,"AF Dev Key is empty","AF dev key cannot be empty");
        }

        boolean getGCD = (boolean) call.argument(AppsFlyerConstants.AF_GCD);

        if (getGCD) {
            gcdListener = registerConversionListener(instance);
        }

        boolean isDebug = (boolean) call.argument(AppsFlyerConstants.AF_IS_DEBUG);
        if (isDebug) {
            instance.setLogLevel(AFLogger.LogLevel.DEBUG);
            instance.setDebugLog(true);
        } else {
            instance.setDebugLog(false);
        }

        instance.init(afDevKey, gcdListener, mContext);
        instance.trackEvent(mContext, null, null);
        instance.startTracking(mApplication, afDevKey);

        result.success("success");
    }

    private void logEvent(MethodCall call, MethodChannel.Result result) {

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
            public void onConversionDataSuccess(Map<String, Object> map) {
                handleSuccess(AF_ON_INSTALL_CONVERSION_DATA_LOADED, map, AF_EVENTS_CHANNEL);
            }

            @Override
            public void onConversionDataFail(String s) {
                handleError(AF_ON_INSTALL_CONVERSION_DATA_LOADED, s, AF_EVENTS_CHANNEL);
            }

            @Override
            public void onAppOpenAttribution(Map<String, String> map) {
                Map<String, Object> objMap = (Map)map;
                handleSuccess(AF_ON_APP_OPEN_ATTRIBUTION,objMap, AF_EVENTS_CHANNEL);
            }

            @Override
            public void onAttributionFailure(String errorMessage) {
                handleError(AF_ON_APP_OPEN_ATTRIBUTION, errorMessage, AF_EVENTS_CHANNEL);
            }
        };
    }

    private void handleSuccess(String eventType, Map<String, Object> data, String channel) {
        try {
            JSONObject obj = new JSONObject();
            obj.put("status", AF_SUCCESS);
            obj.put("type", eventType);
            obj.put("data", new JSONObject(replaceNullValues(data)));

            sendEventToDart(obj, channel);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private Map<String,Object> replaceNullValues(Map<String,Object> map)
    {
        // cant use stream because of older versions of java
        Map<String,Object> newMap = new HashMap<
                >();
        Iterator it = map.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry<String,Object> pair = (Map.Entry)it.next();
            newMap.put(pair.getKey(), pair.getValue() == null ?  JSONObject.NULL : pair.getValue());
            it.remove(); // avoids a ConcurrentModificationException
        }

        return newMap;
    }

    private void handleError(String eventType, String errorMessage, String channel) {

        try {
            JSONObject obj = new JSONObject();

            obj.put("status", AF_FAILURE);
            obj.put("type", eventType);
            obj.put("data", errorMessage);

            sendEventToDart(obj, channel);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void sendEventToDart(final JSONObject params, String channel) {
        Intent intent = new Intent();
        intent.addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES);
        intent.setAction(AppsFlyerConstants.AF_BROADCAST_ACTION_NAME);
        intent.putExtra("params",params.toString());
        mContext.sendBroadcast(intent);
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        onAttachedToEngine(binding.getApplicationContext(),binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        mContext = null;
        mMethodChannel.setMethodCallHandler(null);
        mMethodChannel = null;
        mEventChannel.setStreamHandler(null);
        mEventChannel = null;
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
       mIntent = binding.getActivity().getIntent();
       mApplication = binding.getActivity().getApplication();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }
}
