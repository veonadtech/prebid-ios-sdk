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

target 'PrebidMobileGAMEventHandlers' do
  event_handlers_project
  gma_pods
end

target 'PrebidMobileGAMEventHandlersTests' do
  event_handlers_project
  gma_pods
end

target 'PrebidMobileAdMobAdapters' do
  event_handlers_project
  gma_pods
  
end

target 'PrebidMobileAdMobAdaptersTests' do
  event_handlers_project
  gma_pods
end

target 'PrebidMobileMAXAdapters' do
  event_handlers_project
  applovin_pods
end

target 'PrebidMobileMAXAdaptersTests' do
  event_handlers_project
  applovin_pods
end


target 'PrebidRemoteConfig' do
  event_handlers_project
  # PrebidMobile.framework is linked directly from PrebidMobile.xcodeproj
  # (same workspace) by scripts/addMultiAdLoaderTests.rb — do NOT add
  # `pod 'PrebidMobile'` here, it would pull the public CocoaPods trunk pod
  # instead and duplicate every PrebidMobile symbol.
end

target 'PrebidMultiAdLoaderTests' do
  event_handlers_project
end

target 'PrebidMultiAdLoader' do
  event_handlers_project
  # PrebidMobile and PrebidRemoteConfig — local targets, linked directly, not pods.
end

target 'PrebidMultiAdLoaderGAM' do
  event_handlers_project
  gma_pods
  # PrebidMultiAdLoader и PrebidRemoteConfig — локальные таргеты
end

target 'PrebidMultiAdLoaderGAMTests' do
  event_handlers_project
  gma_pods
end

target 'PrebidMultiAdLoaderYandex' do
  event_handlers_project
  yandex_pods
  # PrebidMultiAdLoader и PrebidRemoteConfig — локальные таргеты
end

target 'PrebidMultiAdLoaderYandexTests' do
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

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end
