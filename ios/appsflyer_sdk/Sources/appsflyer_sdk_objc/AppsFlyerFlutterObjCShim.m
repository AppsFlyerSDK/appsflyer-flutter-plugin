//
//  AppsFlyerFlutterObjCShim.m
//  appsflyer_sdk
//

#import "AppsFlyerFlutterObjCShim.h"

// AppsFlyerRPC bridge (Swift, @objcMembers). Under use_frameworks!/modular headers the generated
// ObjC interface is exposed as <AppsFlyerRPC/AppsFlyerRPC-Swift.h>; fall back to a module import.
#if __has_include(<AppsFlyerRPC/AppsFlyerRPC-Swift.h>)
#import <AppsFlyerRPC/AppsFlyerRPC-Swift.h>
#else
@import AppsFlyerRPC;
#endif

NSException *AFFlutterRunCatchingNSException(NS_NOESCAPE void (^body)(void)) {
    @try {
        body();
    } @catch (NSException *exception) {
        return exception;
    }
    return nil;
}

@implementation AFFlutterRPCBridge

+ (void)executeJson:(NSString *)jsonRequest completion:(void (^)(NSString *response))completion {
    [[AppsFlyerRPCBridge shared] executeJson:jsonRequest completion:completion];
}

+ (void)setEventHandler:(void (^)(NSString *jsonEvent))handler {
    [[AppsFlyerRPCBridge shared] setEventHandler:handler];
}

+ (void)removeEventHandler {
    [[AppsFlyerRPCBridge shared] removeEventHandler];
}

@end
