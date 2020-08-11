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

NS_ASSUME_NONNULL_BEGIN

@interface AppsFlyerStreamHandler: NSObject<FlutterStreamHandler, AppsFlyerLibDelegate>

- (void) sendObject:(NSDictionary*) obj;

@end

NS_ASSUME_NONNULL_END
