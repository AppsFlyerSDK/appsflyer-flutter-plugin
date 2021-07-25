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
    NSString *JSONString = [self mapToJson:message withError:error];
    
    //use callbacks
    if([AppsflyerSdkPlugin gcdCallback]){
        NSString *installDataJson = [self mapToJson:installData withError:error];
        NSDictionary *fullResponse = @{
            @"id": afGCDCallback,
            @"data": installDataJson,
            @"status": afSuccess
        };
        JSONString = [self mapToJson:fullResponse withError:error];
        [AppsflyerSdkPlugin.callbackChannel invokeMethod:@"callListener" arguments:JSONString];
        return;
    }else if (error) {
        return;
    }
    _eventSink(JSONString);
}

- (NSString *)mapToJson:(NSDictionary *)data withError:(NSError *)error{
    NSData *JSON = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    NSString *JSONString = [[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];
    return JSONString;
}

- (void)onConversionDataFail:(NSError *)error {
    NSDictionary *errorMessage = @{@"status":afFailure,
                                   @"type":afOnInstallConversionDataLoaded,
                                   @"data":error.localizedDescription};
    NSString *JSONString = [self mapToJson:errorMessage withError:error];
    
    //use callbacks
    if([AppsflyerSdkPlugin gcdCallback]){
        NSDictionary *fullResponse = @{
            @"id": afGCDCallback,
            @"data": error.localizedDescription,
            @"status": afSuccess
        };
        JSONString = [self mapToJson:fullResponse withError:error];
        [AppsflyerSdkPlugin.callbackChannel invokeMethod:@"callListener" arguments:JSONString];
        return;
    }
    
    if (error) {
        return;
    }
    _eventSink(JSONString);
}


- (void)onAppOpenAttribution:(NSDictionary *)attributionData {
    NSDictionary* message = @{
        @"status": afSuccess,
        @"type": afOnAppOpenAttribution,
        @"data": attributionData
    };
    NSError *error;
    NSString *JSONString = [self mapToJson:message withError:error];
    //use callbacks
    if([AppsflyerSdkPlugin oaoaCallback]){
        NSString* attributionDataJson = [self mapToJson:attributionData withError:error];
        NSDictionary *fullResponse = @{
            @"id": afOAOACallback,
            @"data": attributionDataJson,
            @"status": afSuccess
        };
        JSONString = [self mapToJson:fullResponse withError:error];
        [AppsflyerSdkPlugin.callbackChannel invokeMethod:@"callListener" arguments:JSONString];
        return;
    }
    
    if (error) {
        return;
    }
    _eventSink(JSONString);
}

- (void)onAppOpenAttributionFailure:(NSError *)_errorMessage {
    NSDictionary* errorMessage = @{
        @"status": afFailure,
        @"type": afOnAppOpenAttribution,
        @"data": _errorMessage.localizedDescription
        
    };
    NSError *error;
    NSString *JSONString = [self mapToJson:errorMessage withError:error];
    if([AppsflyerSdkPlugin oaoaCallback]){
        NSDictionary *fullResponse = @{
            @"id": afOAOACallback,
            @"data": error.localizedDescription,
            @"status": afSuccess
        };
        JSONString = [self mapToJson:fullResponse withError:error];
        [AppsflyerSdkPlugin.callbackChannel invokeMethod:@"callListener" arguments:JSONString];
        return;
    }
    
    _eventSink(JSONString);
}

- (void)didResolveDeepLink:(AppsFlyerDeepLinkResult* _Nonnull) deepLinkResult {
    if(deepLinkResult.deepLink){
        NSMutableDictionary *message = [[NSMutableDictionary alloc] initWithCapacity:4];
        message[  @"id"] = afUDPCallback;
        message[  @"deepLinkStatus"] = [self getStatusAsString:deepLinkResult.status];
        if(deepLinkResult.deepLink != nil){
            NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithCapacity: deepLinkResult.deepLink.clickEvent.count + 1];
            [params addEntriesFromDictionary:deepLinkResult.deepLink.clickEvent];
            params[@"isDeferred"] = [NSNumber numberWithBool:deepLinkResult.deepLink.isDeferred];
            message [@"deepLinkObj"] = params;
        }
        if (deepLinkResult.error != nil && deepLinkResult.error.localizedDescription) {
            message [@"deepLinkError"] =  deepLinkResult.error.localizedDescription;
            
        }
        NSError *error;
        NSString *JSONString = [self mapToJson:message withError:error];
        //use callbacks
        if([AppsflyerSdkPlugin udpCallback]){
            NSMutableDictionary *fullResponse = [[NSMutableDictionary alloc] initWithCapacity:4];
          
            fullResponse[  @"id"] = afUDPCallback;
            fullResponse[  @"deepLinkStatus"] = [self getStatusAsString:deepLinkResult.status];
            if(deepLinkResult.deepLink != nil){
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity: deepLinkResult.deepLink.clickEvent.count + 1];
                [dic addEntriesFromDictionary:deepLinkResult.deepLink.clickEvent];
                dic[@"is_deferred"] = [NSNumber numberWithBool:deepLinkResult.deepLink.isDeferred];
                fullResponse [@"deepLinkObj"] = dic;
                
            }
            if (deepLinkResult.error != nil && deepLinkResult.error.localizedDescription) {
                fullResponse [@"deepLinkError"] =  deepLinkResult.error.localizedDescription;
                
            }
            JSONString = [self mapToJson:fullResponse withError:error];
            [AppsflyerSdkPlugin.callbackChannel invokeMethod:@"callListener" arguments:JSONString];
            return;
        }
        
        if (error) {
            return;
        }
        _eventSink(JSONString);
    }
}

- (void)sendResponseToFlutter:(NSString *)responseID status:(NSString *)status data:(NSDictionary *)data{
    NSError *error;
    NSString *JSONdata;
    
    if(data != nil){
        JSONdata = [self mapToJson:data withError:error];
    }else{
        JSONdata = @"empty data";
    }
    if (error) {
        return;
    }
    NSDictionary *fullResponse = @{
        @"id": responseID,
        @"data": JSONdata,
        @"status": status
    };
    JSONdata = [self mapToJson:fullResponse withError:error];
    [AppsflyerSdkPlugin.callbackChannel invokeMethod:@"callListener" arguments:JSONdata];
}

- (NSString*) getStatusAsString:(AFSDKDeepLinkResultStatus)value{
    switch (value) {
        case AFSDKDeepLinkResultStatusFound:
            return @"FOUND";
        case AFSDKDeepLinkResultStatusNotFound:
            return @"NOT_FOUND";
        default:
            return @"ERROR";
            
    }
}


@end
