Pod::Spec.new do |s|
  s.name             = 'appsflyer_sdk'
  s.version          = '6.17.1'
  s.summary          = 'AppsFlyer Integration for Flutter'
  s.description      = 'AppsFlyer is the market leader in mobile advertising attribution & analytics, helping marketers to pinpoint their targeting, optimize their ad spend and boost their ROI.'
  s.homepage         = 'https://github.com/AppsFlyerSDK/flutter_appsflyer_sdk'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { "Appsflyer" => "build@appsflyer.com" }
  s.source           = { :git => "https://github.com/AppsFlyerSDK/flutter_appsflyer_sdk.git", :tag => s.version.to_s }
  
  s.ios.deployment_target = '12.0'
  s.requires_arc = true
  s.static_framework = true
  if defined?($AppsFlyerPurchaseConnector)
    s.default_subspecs = 'Core', 'PurchaseConnector' 
  else
    s.default_subspecs = 'Core' 
  end

  s.subspec 'Core' do |ss|
    ss.source_files = 'appsflyer_sdk/Sources/**/*.{h,m}'
    ss.public_header_files = 'appsflyer_sdk/Sources/appsflyer_sdk/include/**/*.h'
    ss.dependency 'Flutter'
    ss.ios.dependency 'AppsFlyerFramework','6.17.1'
  end

  s.subspec 'PurchaseConnector' do |ss|
    ss.dependency 'Flutter'
    ss.ios.dependency 'PurchaseConnector', '6.17.1'
    ss.source_files = 'appsflyer_sdk/Sources/purchase_connector/**/*.{swift}'
    ss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) ENABLE_PURCHASE_CONNECTOR=1' }
  end
end
