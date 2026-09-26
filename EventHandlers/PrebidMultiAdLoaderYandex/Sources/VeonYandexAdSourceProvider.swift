//
//  VeonYandexAdSourceProvider.swift
//  PrebidMultiAdLoaderYandex
//
//  Copyright © Veon AdTech.
//

import Foundation
import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

/// Call `VeonYandexAdSourceProvider.register()` once at app startup (next
/// to `Prebid.initializeSDK(...)`) if the app links this optional module
/// and wants Yandex to participate in the ad race.
public enum VeonYandexAdSourceProvider {

    public static func register() {
        // rootViewController is threaded through to VeonYandexBannerSource
        // so it can present modal screens (click-through browser) —
        // previously discarded here, which left presentingViewController
        // permanently nil.
        VeonAdSourceRegistry.shared.registerBannerSource(for: .yandex) { adUnitId, adSize, rootViewController in
            AnyVeonAdSourceLoading(
                VeonYandexBannerSource(adUnitId: adUnitId, adSize: adSize, rootViewController: rootViewController)
            )
        }
        VeonAdSourceRegistry.shared.registerInterstitialSource(for: .yandex) { adUnitId in
            AnyVeonAdSourceLoading(VeonYandexInterstitialSource(adUnitId: adUnitId))
        }
    }
}
