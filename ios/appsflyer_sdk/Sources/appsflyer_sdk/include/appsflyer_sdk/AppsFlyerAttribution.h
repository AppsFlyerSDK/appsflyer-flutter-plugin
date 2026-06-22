//
//  AppsFlyerAttribution.h
//  Pods
//
//  Created by Amit Kremer on 11/02/2021.
//

#ifndef AppsFlyerAttribution_h
#define AppsFlyerAttribution_h
#endif /* AppsFlyerAttribution_h */

#import <AppsFlyerLib/AppsFlyerLib.h>

@interface AppsFlyerAttribution : NSObject
@property NSUserActivity*_Nullable  userActivity;
@property (nonatomic, copy) void (^ _Nullable restorationHandler)(NSArray *_Nullable );
@property NSURL * _Nullable url;
@property NSDictionary * _Nullable options;
@property NSString* _Nullable sourceApplication;
@property id _Nullable annotation;
@property BOOL isBridgeReady;

+ (AppsFlyerAttribution *_Nullable)shared;
- (void) continueUserActivity: (NSUserActivity*_Nullable) userActivity restorationHandler: (void (^_Nullable)(NSArray * _Nullable))restorationHandler;
- (void) handleOpenUrl:(NSURL*_Nullable)url options:(NSDictionary*_Nullable) options;
- (void) handleOpenUrl: (NSURL *_Nullable)url sourceApplication:(NSString*_Nullable)sourceApplication annotation:(id _Nullable )annotation;

@end

static NSString * _Nullable const AF_BRIDGE_SET                  = @"bridge is set";
