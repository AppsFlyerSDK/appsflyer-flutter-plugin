package com.appsflyer.appsflyersdk;

import android.content.Context;
import android.content.IntentFilter;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import io.flutter.plugin.common.EventChannel;

public class AppsFlyerStreamHandler implements EventChannel.StreamHandler {
    private final Context mContext;
    private AppsFlyerBroadcastReceiver appsFlyerBroadcastReceiver;
    
    AppsFlyerStreamHandler(Context context){
        this.mContext = context;
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        appsFlyerBroadcastReceiver = new AppsFlyerBroadcastReceiver(eventSink);
        LocalBroadcastManager.getInstance(mContext).registerReceiver(appsFlyerBroadcastReceiver, new IntentFilter(AppsFlyerConstants.AF_BROADCAST_ACTION_NAME));
    }

    @Override
    public void onCancel(Object o) {
        LocalBroadcastManager.getInstance(mContext).unregisterReceiver(appsFlyerBroadcastReceiver);
        appsFlyerBroadcastReceiver = null;
    }
}
