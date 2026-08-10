//
//  AppsFlyerFlutterObjCShim.h
//  appsflyer_sdk
//
//  The only Objective-C left in the Core plugin. It exists for two things Swift cannot express,
//  and holds no plugin logic of its own.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Runs `body` inside an Objective-C `@try`/`@catch` and returns the raised `NSException`, or `nil`
/// when none was raised.
///
/// Swift cannot catch arbitrary `NSException`s, and Flutter's iOS MethodChannel does not catch them
/// around `handleMethodCall:result:` either, so the boundary that turns a malformed Flutter call
/// into a `FlutterError` instead of an app crash has to stay in Objective-C.
FOUNDATION_EXPORT NSException *_Nullable AFFlutterRunCatchingNSException(NS_NOESCAPE void (^body)(void));

/// Pass-through to `AppsFlyerRPCBridge`.
///
/// `AppsFlyerRPCBridge` is a `@MainActor`-isolated Swift class, so Swift callers cannot reach it
/// from the nonisolated contexts this plugin runs in (Flutter channel handlers, `UIApplication` and
/// `UIScene` delegate callbacks) without giving the plugin actor isolation of its own. Objective-C
/// sees the bridge without isolation checking — exactly how the pre-Swift plugin called it — so the
/// calls keep their original queue, ordering and completion-handler behavior.
@interface AFFlutterRPCBridge : NSObject

+ (void)executeJson:(NSString *)jsonRequest completion:(void (^)(NSString *response))completion;
+ (void)setEventHandler:(void (^)(NSString *jsonEvent))handler;
+ (void)removeEventHandler;

@end

NS_ASSUME_NONNULL_END
