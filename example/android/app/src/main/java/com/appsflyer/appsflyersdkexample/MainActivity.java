package com.appsflyer.appsflyersdkexample;

import android.content.Intent;
import android.os.Bundle;

import com.appsflyer.AppsFlyerLib;
import com.appsflyer.appsflyersdk.AppsflyerSdkPlugin;

//import io.flutter.app.FlutterActivity;
//import io.flutter.plugins.GeneratedPluginRegistrant;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        // getIntent() should always return the most recent
        setIntent(intent);
    }
}
