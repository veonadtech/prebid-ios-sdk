//
//  VeonGAMBannerSource.swift
//  PrebidMultiAdLoaderGAM
//
//  Copyright © Veon AdTech.
//

import UIKit
import GoogleMobileAds
import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

/// Wraps a bare `GAMBannerView` — a direct, untargeted GAM ad request.
/// Deliberately does **not** go through Prebid's GAM event handler /
/// targeting keywords: this source is a straight competitor in the race,
/// not a Prebid-rendered line item.
///
/// `internal` on purpose: the app never sees this type directly, only
/// the type-erased `AnyVeonAdSourceLoading<UIView>` returned by the
/// registered factory in `VeonGAMAdSourceProvider`.
final class VeonGAMBannerSource: NSObject, VeonAdSourceLoading, VeonBannerSourceForwardable {

    typealias AdObject = UIView

    var onLoaded: ((UIView) -> Void)?
    var onFailed: ((Error?) -> Void)?
    
    var sdk: SdkType { .gam }
    weak var bannerDelegateForwarder: VeonBannerEventForwarding?

    private let adUnitId: String?
    private let adSize: CGSize
    private weak var rootViewController: UIViewController?
    private var bannerView: AdManagerBannerView?

    init(adUnitId: String?, adSize: CGSize, rootViewController: UIViewController?) {
        self.adUnitId = adUnitId
        self.adSize = adSize
        self.rootViewController = rootViewController
    }

    func load() {
        guard let adUnitId, !adUnitId.isEmpty else {
            onFailed?(VeonGAMSourceError.missingAdUnitId)
            return
        }

        let gadSize = adSizeFor(cgSize: adSize)
        let banner = AdManagerBannerView(adSize: gadSize)
        banner.adUnitID = adUnitId
        banner.rootViewController = rootViewController
        banner.delegate = self
        bannerView = banner
        banner.load(AdManagerRequest())
    }

    func destroy() {
        bannerView?.delegate = nil
        bannerView?.removeFromSuperview()
        bannerView = nil

        onLoaded = nil
        onFailed = nil
    }
}

extension VeonGAMBannerSource: BannerViewDelegate {

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        onLoaded?(bannerView)
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        onFailed?(error)
    }

    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        bannerDelegateForwarder?.bannerSourceDidRecordImpression(sdk)
    }

    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        bannerDelegateForwarder?.bannerSourceDidRecordClick(sdk)
    }

    func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        bannerDelegateForwarder?.bannerSourceWillPresentScreen(sdk)
    }

    func bannerViewWillDismissScreen(_ bannerView: BannerView) {
        bannerDelegateForwarder?.bannerSourceWillDismissScreen(sdk)
    }

    func bannerViewDidDismissScreen(_ bannerView: BannerView) {
        bannerDelegateForwarder?.bannerSourceDidDismissScreen(sdk)
    }
}

enum VeonGAMSourceError: LocalizedError {
    case missingAdUnitId
    var errorDescription: String? { "GAM ad unit id is missing." }
}
