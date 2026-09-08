//
//  VeonGAMBannerSource.swift
//  PrebidMultiAdLoaderGAM
//
//  Copyright © Veon AdTech.
//

import Foundation
import UIKit
import GoogleMobileAds
import VeonPrebidMultiAdLoader

/// Wraps a bare `GAMBannerView` — a direct, untargeted GAM ad request.
/// Deliberately does **not** go through Prebid's GAM event handler /
/// targeting keywords: this source is a straight competitor in the race,
/// not a Prebid-rendered line item.
final class VeonGAMBannerSource: NSObject, VeonAdSourceLoading {

    typealias AdObject = UIView

    var onLoaded: ((UIView) -> Void)?
    var onFailed: ((Error?) -> Void)?

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
        bannerView = nil
    }
}

extension VeonGAMBannerSource: BannerViewDelegate {

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        onLoaded?(bannerView)
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        onFailed?(error)
    }
}

enum VeonGAMSourceError: LocalizedError {
    case missingAdUnitId
    var errorDescription: String? { "GAM ad unit id is missing." }
}
