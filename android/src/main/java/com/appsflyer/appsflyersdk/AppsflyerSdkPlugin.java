package com.appsflyer.appsflyersdk;

import android.app.Activity;
import android.app.Application;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.appsflyer.AFLogger;
import com.appsflyer.AppsFlyerConversionListener;
import com.appsflyer.AppsFlyerInAppPurchaseValidatorListener;
import com.appsflyer.AppsFlyerLib;
import com.appsflyer.AppsFlyerProperties;
import com.appsflyer.attribution.AppsFlyerRequestListener;
import com.appsflyer.CreateOneLinkHttpTask;
import com.appsflyer.share.CrossPromotionHelper;
import com.appsflyer.share.LinkGenerator;
import com.appsflyer.share.ShareInviteHelper;
import com.appsflyer.deeplink.DeepLinkListener;
import com.appsflyer.deeplink.DeepLinkResult;

import org.json.JSONException;
import org.json.JSONObject;

import java.lang.reflect.Method;
import java.util.ArrayList;
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
    private EventChannel mEventChannel;
    /**
     * Plugin registration.
     */
    //private FlutterView mFlutterView;
    private Context mContext;
    private Application mApplication;
    private Intent mIntent;
    private MethodChannel mMethodChannel;
    private MethodChannel mCallbackChannel;
    final Handler uiThreadHandler = new Handler(Looper.getMainLooper());
    private Activity activity;
    private Boolean gcdCallback = false;
    private Boolean oaoaCallback = false;
    private Boolean udlCallback = false;
    private Boolean validatePurchaseCallback = false;

    private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
        this.mContext = applicationContext;
        this.mEventChannel = new EventChannel(messenger, AF_EVENTS_CHANNEL);
        mEventChannel.setStreamHandler(new AppsFlyerStreamHandler(mContext));
        mMethodChannel = new MethodChannel(messenger, AppsFlyerConstants.AF_METHOD_CHANNEL);
        mMethodChannel.setMethodCallHandler(this);
        mCallbackChannel = new MethodChannel(messenger, AppsFlyerConstants.AF_CALLBACK_CHANNEL);
        mCallbackChannel.setMethodCallHandler(callbacksHandler);
    }

    MethodCallHandler callbacksHandler = new MethodCallHandler() {
        @Override
        public void onMethodCall(MethodCall call, Result result) {
            final String method = call.method;
            if ("startListening".equals(method)) {
                startListening(call.arguments, result);
            } else {
                result.notImplemented();
            }
        }
    };

    private Map<String, Map<String, Object>> mCallbacks = new HashMap<>();

    private void startListening(Object arguments, Result rawResult) {
        // Get callback id
        String callbackName = (String) arguments;
        if(callbackName.equals(AppsFlyerConstants.AF_GCD_CALLBACK)){
            gcdCallback = true;
        }
        if (callbackName.equals(AppsFlyerConstants.AF_OAOA_CALLBACK)){
            oaoaCallback = true;
        }
        if (callbackName.equals(AppsFlyerConstants.AF_UDL_CALLBACK)){
            udlCallback = true;
        }
        if (callbackName.equals(AppsFlyerConstants.AF_VALIDATE_PURCHASE)){
            validatePurchaseCallback = true;
        }
        Map<String, Object> args = new HashMap<>();
        args.put("id", callbackName);
        mCallbacks.put(callbackName, args);

        rawResult.success(null);
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
            case "validateAndLogInAppAndroidPurchase":
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
            case "generateInviteLink":
                generateInviteLink(call, result);
                break;
            case "setAppInviteOneLinkID":
                setAppInivteOneLinkID(call, result);
                break;
            case "logCrossPromotionImpression":
                logCrossPromotionImpression(call, result);
                break;
            case "logCrossPromotionAndOpenStore":
                logCrossPromotionAndOpenStore(call, result);
                break;
            case "setOneLinkCustomDomain":
                setOneLinkCustomDomain(call, result);
                break;
            case "setPushNotification":
                sendPushNotificationData(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void sendPushNotificationData(MethodCall call, Result result) {
        AppsFlyerLib.getInstance().sendPushNotificationData(activity);
        result.success(null);
    }

    private void setOneLinkCustomDomain(MethodCall call, Result result) {
        ArrayList<String> brandDomains = (ArrayList<String>) call.arguments;
        String[] brandDomainsArray = brandDomains.toArray(new String[brandDomains.size()]);
        AppsFlyerLib.getInstance().setOneLinkCustomDomain(brandDomainsArray);
        result.success(null);
    }

    private void logCrossPromotionAndOpenStore(MethodCall call, Result result) {
        String appId = (String)call.argument("appId");
        String campaign = (String)call.argument("campaign");
        Map data = (Map)call.argument("params");

        if (appId != null && !appId.equals("")) {
            CrossPromotionHelper.logAndOpenStore(mContext, appId, campaign, data);
        }
        result.success(null);
    }

    private void logCrossPromotionImpression(MethodCall call, Result result) {
        String appId = (String)call.argument("appId");
        String campaign = (String)call.argument("campaign");
        Map data = (Map)call.argument("data");

        if (appId != null && !appId.equals("")) {
            CrossPromotionHelper.logCrossPromoteImpression(mContext, appId, campaign, data);
        }
        result.success(null);
    }

    private void setAppInivteOneLinkID(MethodCall call, Result result) {
        String oneLinkId = (String) call.argument("oneLinkID");
        if(oneLinkId==null || oneLinkId.length() == 0){
            result.success(null);
        }else{
            AppsFlyerLib.getInstance().setAppInviteOneLink(oneLinkId);
            if(mCallbacks.containsKey("setAppInviteOneLinkIDCallback")){
                JSONObject obj = buildJsonResponse("success", AF_SUCCESS);
                runOnUIThread(obj, "setAppInviteOneLinkIDCallback", AF_SUCCESS);
            }
        }
    }

    private void generateInviteLink(MethodCall call, Result rawResult) {
        String channel = (String) call.argument("channel");
        String customerID = (String) call.argument("customerID");
        String campaign = (String) call.argument("campaign");
        String referrerName = (String) call.argument("referrerName");
        String referrerImageUrl = (String) call.argument("referrerImageUrl");
        String baseDeepLink = (String) call.argument("baseDeeplink");
        String brandDomain = (String) call.argument("brandDomain");

        LinkGenerator linkGenerator = ShareInviteHelper.generateInviteUrl(mContext);

        if (channel != null && !channel.equals("")) {
            linkGenerator.setChannel(channel);
        }
        if (campaign != null && !campaign.equals("")) {
            linkGenerator.setCampaign(campaign);
        }
        if (referrerName != null && !referrerName.equals("")) {
            linkGenerator.setReferrerName(referrerName);
        }
        if (referrerImageUrl != null && !referrerImageUrl.equals("")) {
            linkGenerator.setReferrerImageURL(referrerImageUrl);
        }
        if (customerID != null && !customerID.equals("")) {
            linkGenerator.setReferrerCustomerId(customerID);
        }
        if (baseDeepLink != null && !baseDeepLink.equals("")) {
            linkGenerator.setBaseDeeplink(baseDeepLink);
        }
        if (brandDomain != null && !brandDomain.equals("")) {
            linkGenerator.setBrandDomain(brandDomain);
        }

        CreateOneLinkHttpTask.ResponseListener listener = new CreateOneLinkHttpTask.ResponseListener() {
            JSONObject obj = new JSONObject();

            @Override
            public void onResponse(final String oneLinkUrl) {
                if (mCallbacks.containsKey("generateInviteLinkSuccess")) {
                    try {
                        obj.put("userInviteUrl", oneLinkUrl);
                        runOnUIThread(obj, "generateInviteLinkSuccess", AF_SUCCESS);
                    }catch (JSONException e) {
                        e.printStackTrace();
                    }
                }
            }

            @Override
            public void onResponseError(final String error) {
                if (mCallbacks.containsKey("generateInviteLinkFailure")) {
                    try {
                        obj.put("error", error);
                        runOnUIThread(error, "generateInviteLinkFailure", AF_FAILURE);
                    }catch (JSONException e) {
                        e.printStackTrace();
                    }
                }
            }
        };

        linkGenerator.generateLink(mContext, listener);

        rawResult.success(null);
    }

    private void runOnUIThread(final Object data, final String callbackName, final String status) {
        uiThreadHandler.post(
                new Runnable() {
                    @Override
                    public void run() {
                        Log.d("Callbacks","Calling invokeMethod with: " + data);
                        JSONObject args = new JSONObject();
                        try {
                            args.put("id", callbackName);
                            args.put("status", status);
                            args.put("data", data.toString());
                        }catch (JSONException e) {
                            e.printStackTrace();
                        }
                        mCallbackChannel.invokeMethod("callListener", args.toString());
                    }
                }
        );
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
        AppsFlyerLib.getInstance().validateAndLogInAppPurchase(mContext, publicKey, signature, purchaseData, price,
                currency, additionalParameters);
        result.success(null);
    }

    private void registerValidatorListener() {
        AppsFlyerInAppPurchaseValidatorListener validatorListener = new AppsFlyerInAppPurchaseValidatorListener() {
            @Override
            public void onValidateInApp() {
                try {
                    JSONObject obj = new JSONObject();
                    if(validatePurchaseCallback){
                        runOnUIThread(obj, AppsFlyerConstants.AF_VALIDATE_PURCHASE, AF_SUCCESS);
                    }else{
                        obj.put("status", AF_SUCCESS);
                        sendEventToDart(obj, AF_EVENTS_CHANNEL);
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }

            }

            @Override
            public void onValidateInAppFailure(String s) {
                try {
                    JSONObject obj = new JSONObject();
                    obj.put("error", s);
                    if(validatePurchaseCallback){
                        runOnUIThread(obj, AppsFlyerConstants.AF_VALIDATE_PURCHASE, AF_FAILURE);
                    }else{
                        obj.put("status", AF_FAILURE);
                        sendEventToDart(obj, AF_EVENTS_CHANNEL);
                    }
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
        boolean isStopped = (boolean) call.argument("isStopped");
        AppsFlyerLib.getInstance().stop(isStopped, mContext);
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
        DeepLinkListener udlListener = null;
        AppsFlyerLib instance = AppsFlyerLib.getInstance();

        String afDevKey = (String) call.argument(AppsFlyerConstants.AF_DEV_KEY);
        if (afDevKey == null || afDevKey.equals("")) {
            result.error(null, "AF Dev Key is empty", "AF dev key cannot be empty");
        }

        boolean getGCD = (boolean) call.argument(AppsFlyerConstants.AF_GCD);
        if (getGCD) {
            gcdListener = registerConversionListener();
        }
        // added Unified deeplink 
        boolean getUdl = (boolean) call.argument(AppsFlyerConstants.AF_UDL);
        if (getUdl) {
            udlListener = registerOnDeeplinkingListener();
            instance.subscribeForDeepLink(udlListener);
        }

        boolean isDebug = (boolean) call.argument(AppsFlyerConstants.AF_IS_DEBUG);
        if (isDebug) {
            instance.setLogLevel(AFLogger.LogLevel.DEBUG);
            instance.setDebugLog(true);
        } else {
            instance.setDebugLog(false);
        }

        instance.init(afDevKey, gcdListener, mContext);

        String appInviteOneLink = (String) call.argument(AppsFlyerConstants.AF_APP_INVITE_ONE_LINK);
        if(appInviteOneLink != null){
            instance.setAppInviteOneLink(appInviteOneLink);
        }

        instance.start(activity);

        result.success("success");
    }

    private void logEvent(MethodCall call, MethodChannel.Result result) {

        AppsFlyerLib instance = AppsFlyerLib.getInstance();

        final String eventName = call.argument(AppsFlyerConstants.AF_EVENT_NAME);
        final Map<String, Object> eventValues = call.argument(AppsFlyerConstants.AF_EVENT_VALUES);

        // Send event data through appsflyer sdk
        instance.logEvent(mContext, eventName, eventValues);

        result.success(true);
    }

    private DeepLinkListener registerOnDeeplinkingListener() {
        return new DeepLinkListener() {
            @Override
            public void onDeepLinking(DeepLinkResult deepLinkResult) {
                if(udlCallback){
                    runOnUIThread(deepLinkResult, AppsFlyerConstants.AF_UDL_CALLBACK, AF_SUCCESS);
                }else{
                    try {
                        JSONObject obj = new JSONObject();
                        obj.put("status", AF_SUCCESS);
                        obj.put("type", AppsFlyerConstants.AF_UDL_CALLBACK);
                        obj.put("data", deepLinkResult.getDeepLink().getClickEvent());

                        sendEventToDart(obj, AF_EVENTS_CHANNEL);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }
            }
        };
    }

    private AppsFlyerConversionListener registerConversionListener() {
        return new AppsFlyerConversionListener() {
            @Override
            public void onConversionDataSuccess(Map<String, Object> map) {
                if(gcdCallback){
                    JSONObject dataObj = new JSONObject(replaceNullValues(map));
                    runOnUIThread(dataObj, AppsFlyerConstants.AF_GCD_CALLBACK, AF_SUCCESS);
                }else{
                    handleSuccess(AF_ON_INSTALL_CONVERSION_DATA_LOADED,map,AF_EVENTS_CHANNEL);
                }
            }

            @Override
            public void onConversionDataFail(String s) {
                if(gcdCallback){
                    JSONObject obj = buildJsonResponse(s, AF_FAILURE);
                    runOnUIThread(obj, AppsFlyerConstants.AF_GCD_CALLBACK, AF_FAILURE);
                }else{
                    handleError(AF_ON_INSTALL_CONVERSION_DATA_LOADED, s, AF_EVENTS_CHANNEL);
                }
            }

            @Override
            public void onAppOpenAttribution(Map<String, String> map) {
                Map<String, Object> objMap = (Map) map;
                if(oaoaCallback){
                    JSONObject obj = new JSONObject(replaceNullValues(objMap));
                    runOnUIThread(obj, AppsFlyerConstants.AF_OAOA_CALLBACK, AF_SUCCESS);
                }else{
                    handleSuccess(AF_ON_APP_OPEN_ATTRIBUTION, objMap, AF_EVENTS_CHANNEL);
                }
            }

            @Override
            public void onAttributionFailure(String errorMessage) {
                if(oaoaCallback){
                    JSONObject obj = buildJsonResponse(errorMessage, AF_FAILURE);
                    runOnUIThread(obj, AppsFlyerConstants.AF_OAOA_CALLBACK, AF_FAILURE);
                }else{
                    handleError(AF_ON_APP_OPEN_ATTRIBUTION, errorMessage, AF_EVENTS_CHANNEL);
                }
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

    private JSONObject buildJsonResponse(Object data, String status) {
        JSONObject obj = new JSONObject();
        try {
            obj.put("status", status);
            obj.put("data", data.toString());
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return obj;
    }

    private Map<String, Object> replaceNullValues(Map<String, Object> map) {
        // cant use stream because of older versions of java
        Map<String, Object> newMap = new HashMap<
                >();
        Iterator it = map.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry<String, Object> pair = (Map.Entry) it.next();
            newMap.put(pair.getKey(), pair.getValue() == null ? JSONObject.NULL : pair.getValue());
            it.remove(); // avoids a ConcurrentModificationException
        }

        return newMap;
    }

    private void sendEventToDart(final JSONObject params, String channel) {
        Intent intent = new Intent();
        intent.addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES);
        intent.setAction(AppsFlyerConstants.AF_BROADCAST_ACTION_NAME);
        intent.putExtra("params", params.toString());
        mContext.sendBroadcast(intent);
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        mMethodChannel.setMethodCallHandler(null);
        mMethodChannel = null;
        mEventChannel.setStreamHandler(null);
        mEventChannel = null;
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        activity = binding.getActivity();
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
        activity = null;
    }
}
