package com.appsflyer.appsflyersdk;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Delegate class for AppsflyerSdkPlugin.
 * 
 * Flutter's plugin registration mechanism creates new instances of plugins when the engine
 * is recreated (e.g., when the app goes to background via back button and returns to foreground).
 * 
 * This delegate class is the entry point that Flutter instantiates. It delegates all calls
 * to the singleton {@link AppsflyerSdkPlugin} instance, ensuring state is preserved across
 * engine recreations.
 * 
 * Note: This class must be registered in the plugin's build.gradle or GeneratedPluginRegistrant
 * instead of AppsflyerSdkPlugin directly.
 */
public class AppsflyerSdkPluginDelegate implements FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {

    private static int instanceCounter = 0;
    private final int instanceId;

    public AppsflyerSdkPluginDelegate() {
        instanceId = ++instanceCounter;
        PluginLogger.d("Delegate #" + instanceId + " created (Flutter instantiated a new delegate)");
    }

    /**
     * Gets the singleton implementation instance.
     */
    private AppsflyerSdkPlugin getImpl() {
        return AppsflyerSdkPlugin.getInstance();
    }

    // ==================== FlutterPlugin ====================

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        PluginLogger.d("Delegate #" + instanceId + " onAttachedToEngine -> delegating to singleton");
        getImpl().onAttachedToEngine(binding);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        PluginLogger.d("Delegate #" + instanceId + " onDetachedFromEngine -> delegating to singleton");
        getImpl().onDetachedFromEngine(binding);
    }

    // ==================== ActivityAware ====================

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        PluginLogger.d("Delegate #" + instanceId + " onAttachedToActivity -> delegating to singleton");
        getImpl().onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        PluginLogger.d("Delegate #" + instanceId + " onDetachedFromActivityForConfigChanges -> delegating to singleton");
        getImpl().onDetachedFromActivityForConfigChanges();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        PluginLogger.d("Delegate #" + instanceId + " onReattachedToActivityForConfigChanges -> delegating to singleton");
        getImpl().onReattachedToActivityForConfigChanges(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        PluginLogger.d("Delegate #" + instanceId + " onDetachedFromActivity -> delegating to singleton");
        getImpl().onDetachedFromActivity();
    }

    // ==================== MethodCallHandler ====================

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        getImpl().onMethodCall(call, result);
    }
}
