//
//  VeonBannerEventForwarding.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//

import Foundation
import VeonPrebidRemoteConfig

/// `VeonMultiBannerAdLoader` conforms to this to receive engagement
/// events from any banner source, regardless of concrete SDK.
/// Mirrors `VeonInterstitialEventForwarding`.
public protocol VeonBannerEventForwarding: AnyObject {
    func bannerSourceDidRecordImpression(_ sdk: SdkType)
    func bannerSourceDidRecordClick(_ sdk: SdkType)
    func bannerSourceWillLeaveApplication(_ sdk: SdkType)
    func bannerSourceWillPresentScreen(_ sdk: SdkType)
    func bannerSourceWillDismissScreen(_ sdk: SdkType)
    func bannerSourceDidDismissScreen(_ sdk: SdkType)
}
