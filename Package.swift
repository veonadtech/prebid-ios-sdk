// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(

    name: "VeonPrebidMobile",

    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "VeonPrebidMobile",
            targets: ["PrebidMobile", "__PrebidMobileInternal"]
        ),
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
        // New — verify exact package/product name against whatever version
        // you pin elsewhere; Yandex has had naming differences across
        // major SDK versions.
        .package(url: "https://github.com/yandexmobile/yandex-ads-sdk-ios.git", .upToNextMajor(from: "8.0.0")),
    ],
    targets: [
        .target(
            name: "PrebidMobile",
            path: "PrebidMobile",
            sources: ["Swift"]
        ),
        .target(
            name: "__PrebidMobileInternal",
            dependencies: [
                "PrebidMobile",
                "PrebidMobileOMSDK",
            ],
            path: "PrebidMobile",
            sources: ["Objc"],
            cSettings: [
                .headerSearchPath("./Objc/PrivateHeaders"),
                .define("PrebidMobile_SPM", to: "1"),
            ]
        ),
        .binaryTarget(
            name: "PrebidMobileOMSDK",
            path: "Frameworks/OMSDK_Prebidorg.xcframework"
        ),
        .target(
            name: "VeonPrebidMobileAdMobAdapters",
            dependencies: [
                "PrebidMobile",
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "EventHandlers/PrebidMobileAdMobAdapters",
            sources: ["Sources"]
        ),
        .target(
            name: "VeonPrebidMobileGAMEventHandlers",
            dependencies: [
                "PrebidMobile",
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "EventHandlers/PrebidMobileGAMEventHandlers",
            sources: ["Sources"]
        ),
        .target(
            name: "VeonPrebidMobileMAXAdapters",
            dependencies: [
                "PrebidMobile",
                .product(name: "AppLovinSDK", package: "AppLovin-MAX-Swift-Package"),
            ],
            path: "EventHandlers/PrebidMobileMAXAdapters",
            sources: ["Sources"]
        ),
        // New — shared remote config plumbing. No GAM/Yandex dependency.
        .target(
            name: "VeonPrebidRemoteConfig",
            dependencies: [
                "PrebidMobile",
            ],
            path: "EventHandlers/PrebidRemoteConfig",
            sources: ["Sources"]
        ),
        // New — core ad-mediation race engine + Prebid source + the
        // VeonAdSourceRegistry extension point. No GAM/Yandex dependency.
        .target(
            name: "VeonPrebidMultiAdLoader",
            dependencies: [
                "PrebidMobile",
                "VeonPrebidRemoteConfig",
            ],
            path: "EventHandlers/PrebidMultiAdLoader",
            sources: ["Sources"]
        ),
        // New, optional — registers a GAM source into VeonAdSourceRegistry.
        .target(
            name: "VeonPrebidMultiAdLoaderGAM",
            dependencies: [
                "VeonPrebidMultiAdLoader",
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "EventHandlers/PrebidMultiAdLoaderGAM",
            sources: ["Sources"]
        ),
        // New, optional — registers a Yandex source into VeonAdSourceRegistry.
        .target(
            name: "VeonPrebidMultiAdLoaderYandex",
            dependencies: [
                "VeonPrebidMultiAdLoader",
                .product(name: "YandexMobileAds", package: "yandex-ads-sdk-ios"),
            ],
            path: "EventHandlers/PrebidMultiAdLoaderYandex",
            sources: ["Sources"]
        ),
    ]
)
