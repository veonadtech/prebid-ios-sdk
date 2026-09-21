//
//  VeonLoadedInterstitial.swift
//  PrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//

import UIKit
import VeonPrebidRemoteConfig

/// A loaded, ready-to-show interstitial from one of the raced SDKs.
/// `VeonMultiInterstitialAdLoader` holds on to the winning instance and
/// forwards `show(from:)` to it.
public protocol VeonLoadedInterstitial: AnyObject {
    var sdk: SdkType { get }
    func show(from viewController: UIViewController)
}
