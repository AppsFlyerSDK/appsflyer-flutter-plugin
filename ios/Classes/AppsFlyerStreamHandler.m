//
//  AppsFlyerStreamHandler.m
//  appsflyer_sdk
//
//  Created by Shahar Cohen on 05/09/2019.
//

#import "AppsFlyerStreamHandler.h"

@implementation AppsFlyerStreamHandler {
      FlutterEventSink _eventSink;
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

- (void)onConversionDataSuccess:(NSDictionary *)installData { 
    NSDictionary *message = @{@"status":afSuccess,
                                @"type":afOnInstallConversionDataLoaded,
                                @"data":installData };
    NSError *error;
    NSData *JSON = [NSJSONSerialization dataWithJSONObject:message options:0 error:&error];
    if (error) {
        _eventSink([error localizedDescription]);
    }
    NSString *JSONString = [[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];
    _eventSink(JSONString);
}

- (void)onConversionDataFail:(NSError *)error {
    
    NSDictionary *errorMessage = @{@"status":afFailure,
                                     @"type":afOnInstallConversionDataLoaded,
                                     @"data":error.localizedDescription};
    NSData *JSON = [NSJSONSerialization dataWithJSONObject:errorMessage options:0 error:&error];
    if (error) {
        _eventSink([error localizedDescription]);
    }
    NSString *JSONString = [[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];
    _eventSink(JSONString);
}


- (void)onAppOpenAttribution:(NSDictionary *)attributionData {
    
    NSDictionary* message = @{
                              @"status": afSuccess,
                              @"type": afOnAppOpenAttribution, 
                              @"data": attributionData
                              };
    NSError *error;
    NSData *JSON = [NSJSONSerialization dataWithJSONObject:message options:0 error:&error];
    if (error) {
        _eventSink([error localizedDescription]);
    }
    NSString *JSONString = [[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];
    _eventSink(JSONString);
}

- (void)onAppOpenAttributionFailure:(NSError *)_errorMessage {
    
    NSDictionary* errorMessage = @{
                                   @"status": afFailure,
                                   @"type": afOnAppOpenAttribution,
                                   @"data": _errorMessage.localizedDescription
                                   };
    NSData *JSON = [NSJSONSerialization dataWithJSONObject:errorMessage options:0 error:nil];
    NSString *JSONString = [[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];
    _eventSink(JSONString);
}

- (void)sendObject:(NSDictionary *)message{
    NSError *error;
    NSData *JSON = [NSJSONSerialization dataWithJSONObject:message options:0 error:&error];
    if (error) {
        _eventSink([error localizedDescription]);
    }
    NSString *JSONString = [[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];
    _eventSink(JSONString);
}

@end
