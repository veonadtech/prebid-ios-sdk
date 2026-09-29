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
            name: "VeonPrebidMobileAdMobAdapters",
            targets: ["VeonPrebidMobileAdMobAdapters"]
        ),
        .library(
            name: "VeonPrebidMobileGAMEventHandlers",
            targets: ["VeonPrebidMobileGAMEventHandlers"]
        ),
        .library(
            name: "VeonPrebidMobileMAXAdapters",
            targets: ["VeonPrebidMobileMAXAdapters"]
        ),
        .library(
            name: "VeonPrebidRemoteConfig",
            targets: ["VeonPrebidRemoteConfig"]
        ),
        // Core race engine. No GAM/Yandex dependency — safe to add on its own.
        .library(
            name: "VeonPrebidMultiAdLoader",
            targets: ["VeonPrebidMultiAdLoader"]
        ),
        // Optional: only add if GAM should participate in the ad race.
        .library(
            name: "VeonPrebidMultiAdLoaderGAM",
            targets: ["VeonPrebidMultiAdLoaderGAM"]
        ),
        // Optional: only add if Yandex should participate in the ad race.
        .library(
            name: "VeonPrebidMultiAdLoaderYandex",
            targets: ["VeonPrebidMultiAdLoaderYandex"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", .upToNextMajor(from: "13.0.0")),
        .package(url: "https://github.com/AppLovin/AppLovin-MAX-Swift-Package.git", .upToNextMajor(from: "13.0.0")),
        .package(url: "https://github.com/veonadtech/prebid-ios-sdk.git", .upToNextMajor(from: "0.2.0")),
        .package(url: "https://github.com/yandexmobile/yandex-ads-sdk-ios.git", upToNextMinor(from: "8.4.0")),
    ],
    targets: [
        .target(
            name: "VeonPrebidMobileAdMobAdapters",
            dependencies: [
                .product(name: "VeonPrebidMobile", package: "prebid-ios-sdk"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "PrebidMobileAdMobAdapters",
            sources: ["Sources"]
        ),
        .target(
            name: "VeonPrebidMobileGAMEventHandlers",
            dependencies: [
                .product(name: "VeonPrebidMobile", package: "prebid-ios-sdk"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "PrebidMobileGAMEventHandlers",
            sources: ["Sources"]
        ),
        .target(
            name: "VeonPrebidMobileMAXAdapters",
            dependencies: [
                .product(name: "VeonPrebidMobile", package: "prebid-ios-sdk"),
                .product(name: "AppLovinSDK", package: "AppLovin-MAX-Swift-Package"),
            ],
            path: "PrebidMobileMAXAdapters",
            sources: ["Sources"]
        ),
        // New — shared remote config plumbing. No GAM/Yandex dependency.
        .target(
            name: "VeonPrebidRemoteConfig",
            dependencies: [
                .product(name: "VeonPrebidMobile", package: "prebid-ios-sdk"),
            ],
            path: "PrebidRemoteConfig",
            sources: ["Sources"]
        ),
        // New — core ad-mediation race engine + Prebid source + the
        // VeonAdSourceRegistry extension point. No GAM/Yandex dependency.
        .target(
            name: "VeonPrebidMultiAdLoader",
            dependencies: [
                .product(name: "VeonPrebidMobile", package: "prebid-ios-sdk"),
                "VeonPrebidRemoteConfig",
            ],
            path: "PrebidMultiAdLoader",
            sources: ["Sources"]
        ),
        // New, optional — registers a GAM source into VeonAdSourceRegistry.
        .target(
            name: "VeonPrebidMultiAdLoaderGAM",
            dependencies: [
                "VeonPrebidMultiAdLoader",
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "PrebidMultiAdLoaderGAM",
            sources: ["Sources"]
        ),
        // New, optional — registers a Yandex source into VeonAdSourceRegistry.
        .target(
            name: "VeonPrebidMultiAdLoaderYandex",
            dependencies: [
                "VeonPrebidMultiAdLoader",
                .product(name: "YandexMobileAds", package: "yandex-ads-sdk-ios"),
            ],
            path: "PrebidMultiAdLoaderYandex",
            sources: ["Sources"]
        ),
    ]
)
