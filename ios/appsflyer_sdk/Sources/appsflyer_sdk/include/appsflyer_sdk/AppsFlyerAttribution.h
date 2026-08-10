//
//  AppsFlyerAttribution.h
//  Pods
//
//  Created by Amit Kremer on 11/02/2021.
//

#ifndef AppsFlyerAttribution_h
#define AppsFlyerAttribution_h

#import <UIKit/UIKit.h>

@interface AppsFlyerAttribution : NSObject

+ (AppsFlyerAttribution *_Nullable)shared;
- (void)continueUserActivity:(NSUserActivity *_Nullable)userActivity;
- (void) handleOpenUrl:(NSURL*_Nullable)url options:(NSDictionary*_Nullable) options;
- (void) handleOpenUrl: (NSURL *_Nullable)url sourceApplication:(NSString*_Nullable)sourceApplication annotation:(id _Nullable )annotation;
- (void) markBridgeReady;

@end

#endif /* AppsFlyerAttribution_h */
