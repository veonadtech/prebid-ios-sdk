//
//  VeonMultiInterstitialAdLoaderDelegate.swift
//  VeonPrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//

import VeonPrebidRemoteConfig

/// Receives events from a `VeonMultiInterstitialAdLoader` race.
public protocol VeonMultiInterstitialAdLoaderDelegate: AnyObject {
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didLoadFrom sdk: SdkType)
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didFailToLoad sdk: SdkType, error: Error?)
    func interstitialLoaderDidFailAll(_ loader: VeonMultiInterstitialAdLoader)
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, willPresent sdk: SdkType)
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didDismiss sdk: SdkType)
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didClick sdk: SdkType)
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didFailToShow sdk: SdkType, error: Error?)
    /// Not every SDK fires this — see `VeonInterstitialEventForwarding` doc comment.
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didTrackImpression sdk: SdkType)
}

public extension VeonMultiInterstitialAdLoaderDelegate {
    func interstitialLoaderDidFailAll(_ loader: VeonMultiInterstitialAdLoader) {}
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, willPresent sdk: SdkType) {}
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didDismiss sdk: SdkType) {}
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didClick sdk: SdkType) {}
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didFailToShow sdk: SdkType, error: Error?) {}
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didTrackImpression sdk: SdkType) {}
}
