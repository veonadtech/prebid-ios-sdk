//
//  VeonYandexBannerSource.swift
//  PrebidMultiAdLoaderYandex
//
//  Copyright © Veon AdTech.
//

import Foundation
import UIKit
import YandexMobileAds
import VeonPrebidMultiAdLoader

/// Wraps a bare Yandex `BannerAdView` — a direct Yandex ad request,
/// independent of Prebid/GAM.
final class VeonYandexBannerSource: NSObject, VeonAdSourceLoading, VeonAdSourceEngagementReporting {

    typealias AdObject = UIView

    // MARK: - Loading callbacks
    var onLoaded: ((UIView) -> Void)?
    var onFailed: ((Error?) -> Void)?

    // MARK: - VeonAdSourceEngagementReporting (SDK-agnostic, for Core)
    var onImpressionRecorded: (() -> Void)?
    var onClickRecorded: (() -> Void)?
    var onScreenWillPresent: (() -> Void)?
    var onScreenWillDismiss: (() -> Void)?   // Yandex has no "will dismiss" event; never fired
    var onScreenDidDismiss: (() -> Void)?
    var onWillLeaveApplication: (() -> Void)?

    private let adUnitId: String?
    private let adSize: CGSize
    private var adView: AdView?

    weak var presentingViewController: UIViewController?

    init(adUnitId: String?, adSize: CGSize) {
        self.adUnitId = adUnitId
        self.adSize = adSize
    }

    func yandexBannerSize() -> BannerAdSize {
        BannerAdSize.fixedSize(withWidth: adSize.width, height: adSize.height)
    }

    func load() {
        guard let adUnitId, !adUnitId.isEmpty else {
            onFailed?(VeonYandexSourceError.missingAdUnitId)
            return
        }
        
        adView = AdView(adUnitID: adUnitId, adSize: yandexBannerSize())
        adView?.delegate = self
        adView?.translatesAutoresizingMaskIntoConstraints = false
        
        let request = MutableAdRequest()
        adView?.loadAd(with: request)
    }

    func destroy() {
        adView?.delegate = nil
        adView?.removeFromSuperview()
        adView = nil

        onLoaded = nil
        onFailed = nil
        onImpressionRecorded = nil
        onClickRecorded = nil
        onScreenWillPresent = nil
        onScreenWillDismiss = nil
        onScreenDidDismiss = nil
        onWillLeaveApplication = nil
    }
}

extension VeonYandexBannerSource: AdViewDelegate {

    func viewControllerForPresentingModalView() -> UIViewController? {
        presentingViewController
    }

    func adViewDidLoad(_ adView: AdView) {
        onLoaded?(adView)
    }

    func adViewDidFailLoading(_ adView: AdView, error: Error) {
        onFailed?(error)
    }

    func adViewDidClick(_ adView: AdView) {
        onClickRecorded?()
    }

    func adViewWillLeaveApplication(_ adView: AdView) {
        onWillLeaveApplication?()
    }

    func adView(_ adView: AdView, willPresentScreen viewController: UIViewController?) {
        onScreenWillPresent?()
    }

    func adView(_ adView: AdView, didDismissScreen viewController: UIViewController?) {
        onScreenDidDismiss?()
    }

    func adView(_ adView: AdView, didTrackImpression impressionData: (any ImpressionData)?) {
        onImpressionRecorded?()
    }
}

enum VeonYandexSourceError: LocalizedError {
    case missingAdUnitId
    var errorDescription: String? { "Yandex ad unit id is missing." }
}
