//
//  AppsFlyerAttribution.m
//  flutter-appsflyer
//
//  Created by Amit Kremer on 11/02/2021.
//

#import <Foundation/Foundation.h>
#import "AppsFlyerAttribution.h"

#if __has_include(<AppsFlyerRPC/AppsFlyerRPC-Swift.h>)
#import <AppsFlyerRPC/AppsFlyerRPC-Swift.h>
#else
@import AppsFlyerRPC;
#endif

@interface AppsFlyerAttribution ()
@property (nonatomic, assign) BOOL isBridgeReady;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *pendingRequests;
- (void)executeMethod:(NSString *)method params:(NSDictionary *)params;
- (void)executeOrQueueMethod:(NSString *)method params:(NSDictionary *)params;
- (NSDictionary *)jsonSafeOptionsFromDictionary:(NSDictionary *)options;
- (id)jsonSafeValue:(id)value;
@end

@implementation AppsFlyerAttribution

+ (id)shared {
    static AppsFlyerAttribution *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (id)init {
    if (self = [super init]) {
        self.pendingRequests = [NSMutableArray array];
        self.isBridgeReady = NO;
  }
  return self;
}

- (void)continueUserActivity:(NSUserActivity *_Nullable)userActivity {
    if (userActivity.webpageURL == nil) {
        return;
    }
    [self executeOrQueueMethod:@"continueUserActivity" params:@{
        @"url": userActivity.webpageURL.absoluteString,
        @"activityType": userActivity.activityType ?: NSUserActivityTypeBrowsingWeb
    }];
}

- (void) handleOpenUrl:(NSURL *)url options:(NSDictionary *)options{
    if (url == nil) {
        return;
    }
    [self executeOrQueueMethod:@"handleOpenUrl" params:@{
        @"url": url.absoluteString,
        @"options": [self jsonSafeOptionsFromDictionary:options]
    }];
}

- (void) handleOpenUrl:(NSURL *)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation{
    if (url == nil) {
        return;
    }
    NSMutableDictionary *rawOptions = [NSMutableDictionary dictionary];
    if (sourceApplication) {
        rawOptions[UIApplicationOpenURLOptionsSourceApplicationKey] = sourceApplication;
    }
    if (annotation) {
        rawOptions[UIApplicationOpenURLOptionsAnnotationKey] = annotation;
    }
    [self executeOrQueueMethod:@"handleOpenURL" params:@{
        @"url": url.absoluteString,
        @"options": [self jsonSafeOptionsFromDictionary:rawOptions]
    }];
}

- (void)markBridgeReady {
    self.isBridgeReady = YES;
    NSArray<NSDictionary *> *requests = [self.pendingRequests copy];
    [self.pendingRequests removeAllObjects];
    for (NSDictionary *request in requests) {
        [self executeMethod:request[@"method"] params:request[@"params"]];
    }
}

- (void)executeOrQueueMethod:(NSString *)method params:(NSDictionary *)params {
    if (self.isBridgeReady) {
        [self executeMethod:method params:params];
    } else {
        [self.pendingRequests addObject:@{
            @"method": method,
            @"params": params ?: @{}
        }];
    }
}

- (NSDictionary *)jsonSafeOptionsFromDictionary:(NSDictionary *)options {
    if (options.count == 0) {
        return @{};
    }
    NSMutableDictionary *safe = [NSMutableDictionary dictionaryWithCapacity:options.count];
    [options enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        if (![key isKindOfClass:[NSString class]]) {
            return;
        }
        id jsonSafeValue = [self jsonSafeValue:value];
        if (jsonSafeValue != nil) {
            safe[key] = jsonSafeValue;
        }
    }];
    return safe;
}

- (id)jsonSafeValue:(id)value {
    if (value == nil || value == [NSNull null]) {
        return nil;
    }
    if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
        return [NSJSONSerialization isValidJSONObject:value] ? value : nil;
    }
    return [NSJSONSerialization isValidJSONObject:@[value]] ? value : nil;
}

- (void)executeMethod:(NSString *)method params:(NSDictionary *)params {
    NSDictionary *envelope = @{@"method": method, @"params": params ?: @{}};
    if (![NSJSONSerialization isValidJSONObject:envelope]) {
        return;
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:envelope options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (json) {
        [[AppsFlyerRPCBridge shared] executeJson:json completion:^(__unused NSString *response) {}];
    }
}
@end
