//
//  VeonInterstitialSourceForwardable.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//
/// Lets `VeonMultiInterstitialAdLoader` hand itself to any interstitial
/// source — regardless of concrete SDK type — so the source can forward
/// show/dismiss/click lifecycle events back through `VeonInterstitialEventForwarding`.
public protocol VeonInterstitialSourceForwardable: AnyObject {
    var interstitialDelegateForwarder: VeonInterstitialEventForwarding? { get set }
}
