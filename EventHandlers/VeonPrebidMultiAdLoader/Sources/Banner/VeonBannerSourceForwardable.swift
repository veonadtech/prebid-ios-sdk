//
//  VeonBannerSourceForwardable.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//

import VeonPrebidRemoteConfig

/// Lets `VeonMultiBannerAdLoader` hand itself to any banner source so the
/// source can forward its own SDK's engagement callbacks. `sdk` lets the
/// forwarder identify who fired the event — `AdObject` here is a plain
/// `UIView` and carries no SDK identity on its own, unlike interstitials.
public protocol VeonBannerSourceForwardable: AnyObject {
    var sdk: SdkType { get }
    var bannerDelegateForwarder: VeonBannerEventForwarding? { get set }
}
