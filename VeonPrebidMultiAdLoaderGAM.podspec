Pod::Spec.new do |s|
  s.name             = "VeonPrebidMultiAdLoaderGAM"
  s.version          = "0.2.0"
  s.summary          = "GAM sources for VeonPrebidMultiAdLoader. Optional — only add if you want GAM in the race."
  s.module_name      = "VeonPrebidMultiAdLoaderGAM"
  s.description      = "Registers a GAM banner/interstitial source with VeonAdSourceRegistry. Call " \
                        "VeonGAMAdSourceProvider.register() once at app startup after adding this pod."
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

  s.source_files = 'EventHandlers/PrebidMultiAdLoaderGAM/Sources/**/*.{h,m,swift}'
  s.static_framework = true

  s.dependency 'VeonPrebidMultiAdLoader', '>= 0.2.0'
  s.dependency 'VeonPrebidRemoteConfig', '>= 0.2.0'
  s.dependency 'Google-Mobile-Ads-SDK', '< 13.0.0'

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
    'DEFINES_MODULE' => 'YES',
    'OTHER_SWIFT_FLAGS' => '$(inherited) -no-verify-emitted-module-interface'
  }
end
