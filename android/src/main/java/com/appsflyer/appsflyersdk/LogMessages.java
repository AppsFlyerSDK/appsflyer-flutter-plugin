package com.appsflyer.appsflyersdk;

public final class LogMessages {

    // Prevent the instantiation of this utilities class.
    private LogMessages() {
        throw new IllegalStateException("LogMessages class should not be instantiated");
    }

    public static final String ACTIVITY_NOT_ATTACHED_TO_ENGINE = "Activity isn't attached to the flutter engine";
    public static final String AF_DEV_KEY_IS_EMPTY = "AppsFlyer dev key is empty";
}
