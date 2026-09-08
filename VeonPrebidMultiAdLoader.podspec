Pod::Spec.new do |s|
  s.name             = "VeonPrebidMultiAdLoader"
  s.version          = "0.1.0"
  s.summary          = "Priority-based ad mediation race engine for Veon Prebid iOS SDK (Prebid-only core)."
  s.module_name      = "PrebidMultiAdLoader"
  s.description      = "Core race engine + Prebid banner/interstitial source + VeonAdSourceRegistry, the " \
                        "extension point optional VeonPrebidMultiAdLoaderGAM / VeonPrebidMultiAdLoaderYandex " \
                        "pods register into. Depends on neither GAM nor Yandex."
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

  s.source_files = 'PrebidMultiAdLoader/Sources/**/*.{h,m,swift}'
  s.static_framework = true

  s.dependency 'VeonPrebidMobile', '0.1.1'
  s.dependency 'VeonPrebidRemoteConfig', '0.1.0'

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
    'DEFINES_MODULE' => 'YES',
    'OTHER_SWIFT_FLAGS' => '$(inherited) -no-verify-emitted-module-interface'
  }
end
