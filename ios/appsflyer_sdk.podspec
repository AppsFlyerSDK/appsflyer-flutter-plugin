Pod::Spec.new do |s|
  s.name             = 'appsflyer_sdk'
  s.version          = '7.0.2'
  s.summary          = 'AppsFlyer Integration for Flutter'
  s.description      = 'AppsFlyer is the market leader in mobile advertising attribution & analytics, helping marketers to pinpoint their targeting, optimize their ad spend and boost their ROI.'
  s.homepage         = 'https://github.com/AppsFlyerSDK/flutter_appsflyer_sdk'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { "Appsflyer" => "build@appsflyer.com" }
  s.source           = { :git => "https://github.com/AppsFlyerSDK/flutter_appsflyer_sdk.git", :tag => s.version.to_s }
  
  # SDK 7 requires iOS 13+ (AppsFlyerFramework 7.0.2 and the AppsFlyerRPC bridge both target iOS 13.0).
  s.ios.deployment_target = '13.0'
  s.requires_arc = true
  s.static_framework = true
  # Matches the SPM manifest's swift-tools-version:5.9.
  s.swift_version = '5.9'
  if defined?($AppsFlyerPurchaseConnector)
    s.default_subspecs = 'Core', 'PurchaseConnector' 
  else
    s.default_subspecs = 'Core' 
  end

  s.subspec 'Core' do |ss|
    ss.source_files = 'appsflyer_sdk/Sources/appsflyer_sdk/**/*.swift'
    ss.dependency 'Flutter'
    appsflyer_rpc_version = '7.0.13'
    appsflyer_framework_version = '7.0.2'
    # AppsFlyerRPC default_subspecs is Main, which pulls AppsFlyerFramework (Main). Strict mode
    # must pin RPC/Strict and Framework/Strict together or CocoaPods installs both xcframeworks.
    if defined?($AppsFlyerStrictMode) && $AppsFlyerStrictMode
      ss.ios.dependency 'AppsFlyerRPC/Strict', appsflyer_rpc_version
      ss.ios.dependency 'AppsFlyerFramework/Strict', appsflyer_framework_version
    else
      ss.ios.dependency 'AppsFlyerRPC/Main', appsflyer_rpc_version
      ss.ios.dependency 'AppsFlyerFramework/Main', appsflyer_framework_version
    end
  end

  s.subspec 'PurchaseConnector' do |ss|
    ss.dependency 'Flutter'
    ss.ios.dependency 'PurchaseConnector', '7.0.2'
    ss.source_files = 'PurchaseConnector/**/*.swift'
  
    # GCC_PREPROCESSOR_DEFINITIONS only reaches the Objective-C compiler; the Core plugin is Swift
    # now, so the same opt-in has to be declared as a Swift compilation condition as well.
    ss.pod_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) ENABLE_PURCHASE_CONNECTOR=1',
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) ENABLE_PURCHASE_CONNECTOR'
    }
  end
end
