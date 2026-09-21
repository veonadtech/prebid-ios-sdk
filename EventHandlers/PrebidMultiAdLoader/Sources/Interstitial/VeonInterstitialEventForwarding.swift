//
//  VeonInterstitialEventForwarding.swift
//  PrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//

/// `VeonMultiInterstitialAdLoader` conforms to this to receive
/// show/dismiss/click events from whichever source ends up winning,
/// without each source needing to know about the loader's public
/// delegate type directly. Optional modules' sources (GAM/Yandex) hold
/// a weak reference to this to forward their own SDK's callbacks.
public protocol VeonInterstitialEventForwarding: AnyObject {
    func interstitialSourceWillPresent(_ source: VeonLoadedInterstitial)
    func interstitialSourceDidDismiss(_ source: VeonLoadedInterstitial)
    func interstitialSourceDidClick(_ source: VeonLoadedInterstitial)
    func interstitialSourceDidFailToShow(_ source: VeonLoadedInterstitial, error: Error?)
    func interstitialSourceDidTrackImpression(_ source: VeonLoadedInterstitial)
}
