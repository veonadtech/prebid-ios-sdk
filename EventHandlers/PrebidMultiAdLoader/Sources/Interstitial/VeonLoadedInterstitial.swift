//
//  VeonLoadedInterstitial.swift
//  PrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//

import Foundation
import UIKit
import VeonPrebidRemoteConfig

/// A loaded, ready-to-show interstitial from one of the raced SDKs.
/// `VeonMultiInterstitialAdLoader` holds on to the winning instance and
/// forwards `show(from:)` to it.
public protocol VeonLoadedInterstitial: AnyObject {
    var sdk: SdkType { get }
    func show(from viewController: UIViewController)
}

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
}
