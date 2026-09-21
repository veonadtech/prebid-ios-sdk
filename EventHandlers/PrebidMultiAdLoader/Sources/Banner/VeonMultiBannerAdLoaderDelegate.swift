//
//  VeonMultiBannerAdLoaderDelegate.swift
//  PrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//

import UIKit
import VeonPrebidRemoteConfig

/// Receives events from a `VeonMultiBannerAdLoader` race.
public protocol VeonMultiBannerAdLoaderDelegate: AnyObject {
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didLoad view: UIView, from sdk: SdkType)
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didFailToLoad sdk: SdkType, error: Error?)
    func bannerLoaderDidFailAll(_ loader: VeonMultiBannerAdLoader)

    // New, all with no-op defaults below so existing conformers don't break.
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordImpressionFrom sdk: SdkType)
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordClickFrom sdk: SdkType)
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willLeaveApplication sdk: SdkType)
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willPresentScreenFrom sdk: SdkType)
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willDismissScreenFrom sdk: SdkType)
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didDismissScreenFrom sdk: SdkType)
}

public extension VeonMultiBannerAdLoaderDelegate {
    func bannerLoaderDidFailAll(_ loader: VeonMultiBannerAdLoader) {}
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordImpressionFrom sdk: SdkType) {}
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordClickFrom sdk: SdkType) {}
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willPresentScreenFrom sdk: SdkType) {}
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willLeaveApplication sdk: SdkType) {}
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willDismissScreenFrom sdk: SdkType) {}
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didDismissScreenFrom sdk: SdkType) {}
}
