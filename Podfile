platform :ios, '13.0'

workspace 'PrebidMobile'

project 'PrebidMobile.xcodeproj'
project 'EventHandlers/EventHandlers.xcodeproj'
project 'Example/PrebidDemo/PrebidDemo.xcodeproj'

def gma_pods
  pod 'Google-Mobile-Ads-SDK', '>= 13.6.0'
end

def applovin_pods
  pod 'AppLovinSDK'
end

def yandex_pods
  pod 'YandexMobileAds', '8.4.0'
end

def event_handlers_project
  project 'EventHandlers/EventHandlers.xcodeproj'
  use_frameworks!
end

def ima_pod
  pod 'GoogleAds-IMA-iOS-SDK'
end

def prebid_demo_pods
  use_frameworks!
  
  ima_pod
  gma_pods
  applovin_pods
  yandex_pods
end

def internalTestApp_pods
  use_frameworks!
  
  pod 'Alamofire', '4.9.1'
  pod 'Eureka'
  pod 'SVProgressHUD'
  pod 'RxSwift'
  
  ima_pod
  gma_pods
  applovin_pods
end

target 'VeonPrebidMobileGAMEventHandlers' do
  event_handlers_project
  gma_pods
end

target 'VeonPrebidMobileGAMEventHandlersTests' do
  event_handlers_project
  gma_pods
end

target 'VeonPrebidMobileAdMobAdapters' do
  event_handlers_project
  gma_pods
  
end

target 'VeonPrebidMobileAdMobAdaptersTests' do
  event_handlers_project
  gma_pods
end

target 'VeonPrebidMobileMAXAdapters' do
  event_handlers_project
  applovin_pods
end

target 'VeonPrebidMobileMAXAdaptersTests' do
  event_handlers_project
  applovin_pods
end


target 'VeonPrebidRemoteConfig' do
  event_handlers_project
  # PrebidMobile.framework is linked directly from PrebidMobile.xcodeproj
  # (same workspace) by scripts/addMultiAdLoaderTests.rb — do NOT add
  # `pod 'PrebidMobile'` here, it would pull the public CocoaPods trunk pod
  # instead and duplicate every PrebidMobile symbol.
end

target 'VeonPrebidMultiAdLoaderTests' do
  event_handlers_project
end

target 'VeonPrebidMultiAdLoader' do
  event_handlers_project
  # PrebidMobile and VeonPrebidRemoteConfig — local targets, linked directly, not pods.
end

target 'VeonPrebidMultiAdLoaderGAM' do
  event_handlers_project
  gma_pods
  # VeonPrebidMultiAdLoader and VeonPrebidRemoteConfig — локальные таргеты
end

target 'VeonPrebidMultiAdLoaderGAMTests' do
  event_handlers_project
  gma_pods
end

target 'VeonPrebidMultiAdLoaderYandex' do
  event_handlers_project
  yandex_pods
  # VeonPrebidMultiAdLoader and VeonPrebidRemoteConfig — локальные таргеты
end

target 'VeonPrebidMultiAdLoaderYandexTests' do
  event_handlers_project
  yandex_pods
end


target 'PrebidDemoSwift' do
  project 'Example/PrebidDemo/PrebidDemo.xcodeproj'
  
  prebid_demo_pods
  
  target 'PrebidDemoTests' do
    inherit! :search_paths
  end
end

target 'PrebidDemoObjectiveC' do
  project 'Example/PrebidDemo/PrebidDemo.xcodeproj'
  
  prebid_demo_pods
end

target 'InternalTestApp' do
  project 'InternalTestApp/InternalTestApp.xcodeproj'
  internalTestApp_pods
  
  target 'InternalTestAppTests' do
    inherit! :search_paths
  end
  
  target 'InternalTestAppUITests' do
    inherit! :search_paths
  end
end

target 'InternalTestApp-Skadn' do
  project 'InternalTestApp/InternalTestApp.xcodeproj'
  internalTestApp_pods
end

target 'OpenXMockServer' do
  use_frameworks!
  project 'InternalTestApp/InternalTestApp.xcodeproj'
  
  pod 'Alamofire', '4.9.1'
  pod 'RxSwift'
  
  target 'OpenXMockServerTests' do
    inherit! :search_paths
  end
end

# --- Yandex / AppMetrica ABI fix ---
# YandexMobileAds ships as a prebuilt .xcframework linked against a non-resilient
# (BUILD_LIBRARY_FOR_DISTRIBUTION = NO) build of AppMetricaLibraryAdapter.
# CocoaPods compiles AppMetricaLibraryAdapter from source as part of this
# workspace, and on current Xcode/Swift toolchains it picks up
# BUILD_LIBRARY_FOR_DISTRIBUTION = YES from this project's own targets,
# which changes how `AnalyticsLibraryAdapter.shared` is emitted (a resilient
# accessor instead of a plain addressor) — breaking linkage against Yandex's
# binary with:
#   Undefined symbol: AppMetricaLibraryAdapter.AnalyticsLibraryAdapter.shared.unsafeMutableAddressor
# Known upstream issue, not specific to this project:
#   https://github.com/cleveradssolutions/CAS-Unity/issues/19
#   https://github.com/AppLovin/AppLovin-MAX-Unity-Plugin/issues/573
#   https://github.com/appmetrica/appmetrica-unity-plugin/issues/30
YANDEX_ABI_FIX_TARGETS = %w[
  AppMetricaLibraryAdapter
  AppMetricaCore
  AppMetricaCoreExtension
  AppMetricaCoreUtils
  AppMetricaCrashes
  AppMetricaEncodingUtils
  AppMetricaFMDB
  AppMetricaHostState
  AppMetricaIDSync
  AppMetricaIdentifiers
  AppMetricaKeychain
  AppMetricaLog
  AppMetricaLogSwift
  AppMetricaNetwork
  AppMetricaPlatform
  AppMetricaProtobuf
  AppMetricaProtobufUtils
  AppMetricaStorageUtils
  AppMetricaSynchronization
  AppMetricaAdSupport
].freeze

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'

        if YANDEX_ABI_FIX_TARGETS.include?(target.name)
          config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
        end
      end
    end
  end
end
