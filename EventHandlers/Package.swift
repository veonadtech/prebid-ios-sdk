// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    
    name: "PrebidMobileAdapters",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "PrebidMobileAdMobAdapters",
            targets: ["PrebidMobileAdMobAdapters"]
        ),
        .library(
            name: "PrebidMobileGAMEventHandlers",
            targets: ["PrebidMobileGAMEventHandlers"]
        ),
        .library(
            name: "PrebidMobileMAXAdapters",
            targets: ["PrebidMobileMAXAdapters"]
        ),
        .library(
            name: "PrebidRemoteConfig",
            targets: ["PrebidRemoteConfig"]
        ),
        // Core race engine. No GAM/Yandex dependency — safe to add on its own.
        .library(
            name: "PrebidMultiAdLoader",
            targets: ["PrebidMultiAdLoader"]
        ),
        // Optional: only add if GAM should participate in the ad race.
        .library(
            name: "PrebidMultiAdLoaderGAM",
            targets: ["PrebidMultiAdLoaderGAM"]
        ),
        // Optional: only add if Yandex should participate in the ad race.
        .library(
            name: "PrebidMultiAdLoaderYandex",
            targets: ["PrebidMultiAdLoaderYandex"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", .upToNextMajor(from: "13.0.0")),
        .package(url: "https://github.com/AppLovin/AppLovin-MAX-Swift-Package.git", .upToNextMajor(from: "13.0.0")),
        .package(url: "https://github.com/prebid/prebid-mobile-ios-sdk.git", .upToNextMajor(from: "3.3.4")),
        // New — verify exact package/product name against whatever version
        // you pin elsewhere; Yandex has had naming differences across
        // major SDK versions.
        .package(url: "https://github.com/yandexmobile/yandex-ads-sdk-ios.git", .upToNextMajor(from: "8.0.0")),
    ],
    targets: [
        .target(
            name: "PrebidMobileAdMobAdapters",
            dependencies: [
                .product(name: "PrebidMobile", package: "prebid-mobile-ios-sdk"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "PrebidMobileAdMobAdapters",
            sources: ["Sources"]
        ),
        .target(
            name: "PrebidMobileGAMEventHandlers",
            dependencies: [
                .product(name: "PrebidMobile", package: "prebid-mobile-ios-sdk"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "PrebidMobileGAMEventHandlers",
            sources: ["Sources"]
        ),
        .target(
            name: "PrebidMobileMAXAdapters",
            dependencies: [
                .product(name: "PrebidMobile", package: "prebid-mobile-ios-sdk"),
                .product(name: "AppLovinSDK", package: "AppLovin-MAX-Swift-Package"),
            ],
            path: "PrebidMobileMAXAdapters",
            sources: ["Sources"]
        ),
        // New — shared remote config plumbing. No GAM/Yandex dependency.
        .target(
            name: "PrebidRemoteConfig",
            dependencies: [
                .product(name: "PrebidMobile", package: "prebid-mobile-ios-sdk"),
            ],
            path: "PrebidRemoteConfig",
            sources: ["Sources"]
        ),
        // New — core ad-mediation race engine + Prebid source + the
        // VeonAdSourceRegistry extension point. No GAM/Yandex dependency.
        .target(
            name: "PrebidMultiAdLoader",
            dependencies: [
                .product(name: "PrebidMobile", package: "prebid-mobile-ios-sdk"),
                "PrebidRemoteConfig",
            ],
            path: "PrebidMultiAdLoader",
            sources: ["Sources"]
        ),
        // New, optional — registers a GAM source into VeonAdSourceRegistry.
        .target(
            name: "PrebidMultiAdLoaderGAM",
            dependencies: [
                "PrebidMultiAdLoader",
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "PrebidMultiAdLoaderGAM",
            sources: ["Sources"]
        ),
        // New, optional — registers a Yandex source into VeonAdSourceRegistry.
        .target(
            name: "PrebidMultiAdLoaderYandex",
            dependencies: [
                "PrebidMultiAdLoader",
                .product(name: "YandexMobileAds", package: "yandex-ads-sdk-ios"),
            ],
            path: "PrebidMultiAdLoaderYandex",
            sources: ["Sources"]
        ),
    ]
)
