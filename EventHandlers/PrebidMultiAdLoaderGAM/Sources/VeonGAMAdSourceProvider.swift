//
//  VeonGAMAdSourceProvider.swift
//  PrebidMultiAdLoaderGAM
//
//  Copyright © Veon AdTech.
//

import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

/// Call `VeonGAMAdSourceProvider.register()` once at app startup (next to
/// `Prebid.initializeSDK(...)`) if the app links this optional module and
/// wants GAM to participate in the ad race.
///
/// Without this call, `PrebidMultiAdLoaderGAM` can be linked or not —
/// either way `VeonMultiBannerAdLoader` / `VeonMultiInterstitialAdLoader`
/// just skip `.gam` in the race, the same as if it had failed to load.
public enum VeonGAMAdSourceProvider {

    public static func register() {
        VeonAdSourceRegistry.shared.registerBannerSource(for: .gam) { adUnitId, adSize, rootViewController in
            AnyVeonAdSourceLoading(
                VeonGAMBannerSource(adUnitId: adUnitId, adSize: adSize, rootViewController: rootViewController)
            )
        }
        VeonAdSourceRegistry.shared.registerInterstitialSource(for: .gam) { adUnitId in
            AnyVeonAdSourceLoading(VeonGAMInterstitialSource(adUnitId: adUnitId))
        }
    }
}
