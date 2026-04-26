package com.appsflyer.appsflyersdk;

import android.util.Log;

import java.lang.reflect.Method;

import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_PLUGIN_TAG;

/**
 * Utility class for plugin logging controlled by system property.
 * 
 * Enable logging via ADB (requires app restart):
 *   adb shell setprop debug.appsflyer.flutter true
 * 
 * Disable logging via ADB (requires app restart):
 *   adb shell setprop debug.appsflyer.flutter false
 * 
 * Or enable programmatically:
 *   PluginLogger.setDebugLoggingEnabled(true)
 */
public final class PluginLogger {

    private static final String SYSTEM_PROP_KEY = "debug.appsflyer.flutter";
    
    // Read system property once at class load time
    private static boolean debugEnabled = readSystemProperty();

    private PluginLogger() {
        // Prevent instantiation
    }

    /**
     * Enable or disable debug logging.
     * 
     * @param enabled true to enable logging, false to disable
     */
    public static void setDebugLoggingEnabled(boolean enabled) {
        debugEnabled = enabled;
    }

    /**
     * Log a debug message if logging is enabled.
     * 
     * @param message The message to log
     */
    public static void d(String message) {
        if (debugEnabled) {
            Log.d(AF_PLUGIN_TAG, message);
        }
    }

    /**
     * Read the system property using reflection (called once at class load).
     * 
     * @return true if the property is set to "true", false otherwise
     */
    private static boolean readSystemProperty() {
        try {
            Class<?> systemPropertiesClass = Class.forName("android.os.SystemProperties");
            Method getMethod = systemPropertiesClass.getMethod("get", String.class, String.class);
            String value = (String) getMethod.invoke(null, SYSTEM_PROP_KEY, "false");
            return "true".equalsIgnoreCase(value);
        } catch (Exception e) {
            return false;
        }
    }
}
