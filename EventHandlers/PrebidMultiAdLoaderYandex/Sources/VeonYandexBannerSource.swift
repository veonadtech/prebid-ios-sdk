//
//  VeonYandexBannerSource.swift
//  PrebidMultiAdLoaderYandex
//
//  Copyright © Veon AdTech.
//

import UIKit
import YandexMobileAds
import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

/// Wraps a bare Yandex `BannerAdView` — a direct Yandex ad request,
/// independent of Prebid/GAM.
final class VeonYandexBannerSource: NSObject, VeonAdSourceLoading, VeonBannerSourceForwardable {

    typealias AdObject = UIView

    // MARK: - Loading callbacks
    var onLoaded: ((UIView) -> Void)?
    var onFailed: ((Error?) -> Void)?
    
    var sdk: SdkType { .yandex }
    weak var bannerDelegateForwarder: VeonBannerEventForwarding?


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
        bannerDelegateForwarder?.bannerSourceDidRecordClick(sdk)
    }

    func adViewWillLeaveApplication(_ adView: AdView) {
        bannerDelegateForwarder?.bannerSourceWillLeaveApplication(sdk)
    }

    func adView(_ adView: AdView, willPresentScreen viewController: UIViewController?) {
        bannerDelegateForwarder?.bannerSourceWillPresentScreen(sdk)
    }

    func adView(_ adView: AdView, didDismissScreen viewController: UIViewController?) {
        bannerDelegateForwarder?.bannerSourceDidDismissScreen(sdk)
    }

    func adView(_ adView: AdView, didTrackImpression impressionData: (any ImpressionData)?) {
        bannerDelegateForwarder?.bannerSourceDidRecordImpression(sdk)
    }
}

enum VeonYandexSourceError: LocalizedError {
    case missingAdUnitId
    var errorDescription: String? { "Yandex ad unit id is missing." }
}
