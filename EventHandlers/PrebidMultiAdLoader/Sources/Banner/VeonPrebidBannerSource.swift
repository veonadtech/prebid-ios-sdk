//
//  VeonPrebidBannerSource.swift
//  PrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//

import UIKit
import PrebidMobile
import VeonPrebidRemoteConfig

/// Wraps Prebid's own rendering `BannerView` (no event handler — this is
/// the "Prebid Only Integration" flavor, so Prebid competes purely on its
/// own auction result, without any GAM/Yandex line item involved).
///
/// Lives in Core (not an optional module) because Prebid itself is
/// always a hard dependency of this whole package.
final class VeonPrebidBannerSource: NSObject, VeonAdSourceLoading {

    typealias AdObject = UIView

    var onLoaded: ((UIView) -> Void)?
    var onFailed: ((Error?) -> Void)?

    /// Set by `VeonMultiBannerAdLoader` right after `init`; answers
    /// `bannerViewPresentationController()`.
    weak var presentingViewController: UIViewController?

    private let configId: String?
    private let adSize: CGSize
    private let refreshInterval: TimeInterval?
    private var bannerView: BannerView?

    init(configId: String?, adSize: CGSize, refreshInterval: TimeInterval?) {
        self.configId = configId
        self.adSize = adSize
        self.refreshInterval = refreshInterval
    }

    func load() {
        guard let configId, !configId.isEmpty else {
            onFailed?(VeonMultiAdLoaderError.missingConfigId(sdk: .prebid))
            return
        }

        let banner = BannerView(
            frame: CGRect(origin: .zero, size: adSize),
            configID: configId,
            adSize: adSize
        )
        
        if let refreshInterval {
            banner.refreshInterval = refreshInterval
        }
        
        banner.delegate = self
        bannerView = banner
        banner.loadAd()
    }

    func destroy() {
        bannerView?.delegate = nil
        bannerView?.removeFromSuperview()
        bannerView = nil
    }
}

extension VeonPrebidBannerSource: BannerViewDelegate {

    func bannerViewPresentationController() -> UIViewController? {
        presentingViewController
    }

    func bannerView(_ bannerView: BannerView, didReceiveAdWithAdSize adSize: CGSize) {
        onLoaded?(bannerView)
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWith error: Error) {
        onFailed?(error)
    }
}
