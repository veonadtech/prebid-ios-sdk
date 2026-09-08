//
//  VeonYandexAdSourceProvider.swift
//  PrebidMultiAdLoaderYandex
//
//  Copyright © Veon AdTech.
//

import Foundation
import VeonPrebidMultiAdLoader

/// Call `VeonYandexAdSourceProvider.register()` once at app startup (next
/// to `Prebid.initializeSDK(...)`) if the app links this optional module
/// and wants Yandex to participate in the ad race.
public enum VeonYandexAdSourceProvider {

    public static func register() {
        VeonAdSourceRegistry.shared.registerBannerSource(for: .yandex) { adUnitId, adSize, _ in
            AnyVeonAdSourceLoading(VeonYandexBannerSource(adUnitId: adUnitId, adSize: adSize))
        }
        VeonAdSourceRegistry.shared.registerInterstitialSource(for: .yandex) { adUnitId in
            AnyVeonAdSourceLoading(VeonYandexInterstitialSource(adUnitId: adUnitId))
        }
    }
}
