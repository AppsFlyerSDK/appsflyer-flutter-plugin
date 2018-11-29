#import "AppsflyerSdkPlugin.h"

@implementation AppsflyerSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"appsflyer_sdk"
            binaryMessenger:[registrar messenger]];
  AppsflyerSdkPlugin* instance = [[AppsflyerSdkPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
//  if ([@"getPlatformVersion" isEqualToString:call.method]) {
//    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
//  } else {
//    result(FlutterMethodNotImplemented);
//  }
    if([@"initSdk" isEqualToString:call.method]){
        NSString *devKey = call.arguments[afDevKey];
        NSString *appId = call.arguments[afAppId];
//        NSString *isConversionData = call.arguments[afConversionData];
        NSLog(@"Message == %@",afDevKey);
        [AppsFlyerTracker sharedTracker].appsFlyerDevKey = devKey;
        [AppsFlyerTracker sharedTracker].appleAppID = appId;
        [AppsFlyerTracker sharedTracker].delegate = self;
        [AppsFlyerTracker sharedTracker].isDebug = YES;
//        #ifdef DEBUG
//        [AppsFlyerTracker sharedTracker].isDebug = call.arguments[@"isDebug"] && YES;
//        #endif
        
        [[AppsFlyerTracker sharedTracker] trackAppLaunch];
    }else{
        result(FlutterMethodNotImplemented);
    }
}
    
    -(void)onConversionDataReceived:(NSDictionary*) installData {

        NSDictionary* message = @{
                                  @"status": afSuccess,
                                  @"type": afOnInstallConversionDataLoaded,
                                  @"data": installData
                                  };

        [self performSelectorOnMainThread:@selector(handleCallback:) withObject:message waitUntilDone:NO];
    }

    -(void)onConversionDataRequestFailure:(NSError *) _errorMessage {

        NSDictionary* errorMessage = @{
                                       @"status": afFailure,
                                       @"type": afOnInstallConversionFailure,
                                       @"data": _errorMessage.localizedDescription
                                       };

        [self performSelectorOnMainThread:@selector(handleCallback:) withObject:errorMessage waitUntilDone:NO];
    }


    - (void) onAppOpenAttribution:(NSDictionary*) attributionData {

        NSDictionary* message = @{
                                  @"status": afSuccess,
                                  @"type": afOnAppOpenAttribution,
                                  @"data": attributionData
                                  };

        [self performSelectorOnMainThread:@selector(handleCallback:) withObject:message waitUntilDone:NO];
    }

    - (void) onAppOpenAttributionFailure:(NSError *)_errorMessage {

        NSDictionary* errorMessage = @{
                                       @"status": afFailure,
                                       @"type": afOnAttributionFailure,
                                       @"data": _errorMessage.localizedDescription
                                       };

        [self performSelectorOnMainThread:@selector(handleCallback:) withObject:errorMessage waitUntilDone:NO];
    }


    -(void) handleCallback:(NSDictionary *) message{
        NSError *error;

        NSData *jsonMessage = [NSJSONSerialization dataWithJSONObject:message
                                                              options:0
                                                                error:&error];
        if (jsonMessage) {
            NSString *jsonMessageStr = [[NSString alloc] initWithBytes:[jsonMessage bytes] length:[jsonMessage length] encoding:NSUTF8StringEncoding];

            NSString* status = (NSString*)[message objectForKey: @"status"];
            NSString* type = (NSString*)[message objectForKey: @"type"];

            if([status isEqualToString:afSuccess]){
                [self reportOnSuccess:jsonMessageStr withType:type];
            }
            else{
                [self reportOnFailure:jsonMessageStr withType:type];
            }

            NSLog(@"jsonMessageStr = %@",jsonMessageStr);
        } else {
            NSLog(@"%@",error);
        }
    }

    -(void) reportOnFailure:(NSString *)errorMessage withType:(NSString *)type{

        if([type isEqualToString:afOnAttributionFailure]){
            //TODO
        }
        else if([type isEqualToString:afOnInstallConversionFailure]){
//            if (mConversionListenerOnResume != nil) {
//                mConversionListenerOnResume = nil;
            }

//            if(mConversionListener != nil){
//                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:errorMessage];
//                [pluginResult setKeepCallback:[NSNumber numberWithBool:NO]];
//                [self.commandDelegate sendPluginResult:pluginResult callbackId:mConversionListener];

//                mConversionListener = nil;
//            }
        }
//    }

    -(void) reportOnSuccess:(NSString *)data withType:(NSString *)type {

        if([type isEqualToString:afOnAppOpenAttribution]){
            //TODO: handle attribution
        }
        else if([type isEqualToString:afOnInstallConversionDataLoaded]){
            //TODO
        }
    }

@end
