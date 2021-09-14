//
//  AppsFlyerStreamHandler.m
//  appsflyer_sdk
//
//  Created by Shahar Cohen on 05/09/2019.
//

#import "AppsFlyerStreamHandler.h"

@implementation AppsFlyerStreamHandler {

}

- (void)onConversionDataSuccess:(NSDictionary *)installData {
    NSError *error;

    //use callbacks
    if([AppsflyerSdkPlugin gcdCallback]){
        NSString *installDataJson = [self mapToJson:installData withError:error];
        NSDictionary *fullResponse = @{
            @"id": afGCDCallback,
            @"data": installDataJson,
            @"status": afSuccess
        };
        NSString *JSONString = [self mapToJson:fullResponse withError:error];
        [AppsflyerSdkPlugin.callbackChannel invokeMethod:@"callListener" arguments:JSONString];
        return;
    }else if (error) {
        return;
    }
}

- (NSString *)mapToJson:(NSDictionary *)data withError:(NSError *)error{
    NSData *JSON = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    NSString *JSONString = [[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];
    return JSONString;
}

- (void)onConversionDataFail:(NSError *)error {
    //use callbacks
    if([AppsflyerSdkPlugin gcdCallback]){
        NSDictionary *fullResponse = @{
            @"id": afGCDCallback,
            @"data": error.localizedDescription,
            @"status": afSuccess
        };
        NSString *JSONString = [self mapToJson:fullResponse withError:error];
        [AppsflyerSdkPlugin.callbackChannel invokeMethod:@"callListener" arguments:JSONString];
        return;
    }
    
    if (error) {
        return;
    }
}


- (void)onAppOpenAttribution:(NSDictionary *)attributionData {
    NSError *error;
    //use callbacks
    if([AppsflyerSdkPlugin oaoaCallback]){
        NSString* attributionDataJson = [self mapToJson:attributionData withError:error];
        NSDictionary *fullResponse = @{
            @"id": afOAOACallback,
            @"data": attributionDataJson,
            @"status": afSuccess
        };
        NSString *JSONString = [self mapToJson:fullResponse withError:error];
        [AppsflyerSdkPlugin.callbackChannel invokeMethod:@"callListener" arguments:JSONString];
        return;
    }
    
    if (error) {
        return;
    }
}

- (void)onAppOpenAttributionFailure:(NSError *)_errorMessage {
    NSError *error;
    if([AppsflyerSdkPlugin oaoaCallback]){
        NSDictionary *fullResponse = @{
            @"id": afOAOACallback,
            @"data": error.localizedDescription,
            @"status": afSuccess
        };
        NSString *JSONString = [self mapToJson:fullResponse withError:error];
        [AppsflyerSdkPlugin.callbackChannel invokeMethod:@"callListener" arguments:JSONString];
        return;
    }
    
}

- (void)didResolveDeepLink:(AppsFlyerDeepLinkResult* _Nonnull) deepLinkResult {
        NSError *error;
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
            NSString *JSONString = [self mapToJson:fullResponse withError:error];
            [AppsflyerSdkPlugin.callbackChannel invokeMethod:@"callListener" arguments:JSONString];
            return;
        }
        
        if (error) {
            return;
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
