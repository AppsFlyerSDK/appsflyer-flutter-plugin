//
//  AppsFlyerStreamHandler.h
//  appsflyer_sdk
//
//  Created by Shahar Cohen on 05/09/2019.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

// I will change it to seperate file with #defines
#import "AppsflyerSdkPlugin.h"
#import "AppsFlyerAttribution.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppsFlyerStreamHandler: NSObject<FlutterStreamHandler, AppsFlyerLibDelegate, AppsFlyerDeepLinkDelegate>

- (void)sendResponseToFlutter:(NSString *)responseID status:(NSString *)status data:(NSDictionary *)data;

@end

NS_ASSUME_NONNULL_END
