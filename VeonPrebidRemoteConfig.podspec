Pod::Spec.new do |s|
  s.name             = "VeonPrebidRemoteConfig"
  s.version          = "0.2.0"
  s.summary          = "Shared remote config plumbing for Veon Prebid iOS SDK feature modules."
  s.module_name      = "VeonPrebidRemoteConfig"
  s.description      = "Adds a configURL parameter to Prebid.initializeSDK and stores the raw response " \
                        "for feature modules (ad mediation priority, future logging level, etc.) to decode " \
                        "independently, without those modules depending on each other."
  s.homepage         = "https://www.veon.com"
  s.license          = { :type => "Apache License, Version 2.0" }
  s.author           = { "Veon AdTech" => "veonadtech.com" }
  s.platform         = :ios, "13.0"
  s.swift_version    = "5.0"
  s.source           = { :git => "https://github.com/veonadtech/prebid-ios-sdk.git", :tag => "#{s.version}" }

  s.xcconfig = { :LIBRARY_SEARCH_PATHS => '$(inherited)',
                 :OTHER_CFLAGS => '$(inherited)',
                 :OTHER_LDFLAGS => '$(inherited)',
                 :HEADER_SEARCH_PATHS => '$(inherited)',
                 :FRAMEWORK_SEARCH_PATHS => '$(inherited)'
               }

  s.source_files = 'EventHandlers/PrebidRemoteConfig/Sources/**/*.{h,m,swift}'
  s.static_framework = true

  s.dependency 'VeonPrebidMobile', '>= 0.2.0'

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
    'DEFINES_MODULE' => 'YES',
    'OTHER_SWIFT_FLAGS' => '$(inherited) -no-verify-emitted-module-interface'
  }
end
