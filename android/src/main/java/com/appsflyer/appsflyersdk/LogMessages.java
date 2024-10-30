package com.appsflyer.appsflyersdk;

public final class LogMessages {

    // Prevent the instantiation of this utilities class.
    private LogMessages() {
        throw new IllegalStateException("LogMessages class should not be instantiated");
    }

    public static final String METHOD_CHANNEL_IS_NULL = "mMethodChannel is null, cannot invoke the callback";
    public static final String ACTIVITY_NOT_ATTACHED_TO_ENGINE = "Activity isn't attached to the flutter engine";
}
