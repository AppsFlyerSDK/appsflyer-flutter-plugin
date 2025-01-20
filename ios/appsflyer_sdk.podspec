#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'appsflyer_sdk'
  s.version          = '6.15.3'
  s.summary          = 'AppsFlyer Integration for Flutter'
  s.description      = <<-DESC
AppsFlyer is the market leader in mobile advertising attribution & analytics, helping marketers to pinpoint their targeting, optimize their ad spend and boost their ROI.
                       DESC
  s.homepage         = 'https://github.com/AppsFlyerSDK/flutter_appsflyer_sdk'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { "Appsflyer" => "build@appsflyer.com" }
  s.source           = { :git => "https://github.com/AppsFlyerSDK/flutter_appsflyer_sdk.git", :tag => s.version.to_s }


  s.ios.deployment_target = '12.0'
  s.requires_arc = true
  s.static_framework = true
  
  s.source_files = 'appsflyer_sdk/Sources/**/*.{h,m}'
  s.public_header_files = 'appsflyer_sdk/Sources/appsflyer_sdk/include/**/*.h'
  s.module_map = 'appsflyer_sdk/Sources/appsflyer_sdk/include/appsflyer_sdk.modulemap'
  s.dependency 'Flutter'
  s.ios.dependency 'AppsFlyerFramework','6.15.3'
end
