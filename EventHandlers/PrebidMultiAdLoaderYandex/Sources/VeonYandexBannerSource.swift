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
    private var bannerAdView: BannerAdView?

    // Was declared but never assigned — the factory in
    // VeonYandexAdSourceProvider dropped rootViewController. Now set
    // at init, same as VeonGAMBannerSource / VeonPrebidBannerSource.
    private weak var presentingViewController: UIViewController?

    init(adUnitId: String?, adSize: CGSize, rootViewController: UIViewController?) {
        self.adUnitId = adUnitId
        self.adSize = adSize
        self.presentingViewController = rootViewController
    }

    private func yandexBannerSize() -> BannerAdSize {
        BannerAdSize.fixed(width: adSize.width, height: adSize.height)
    }

    func load() {
        guard let adUnitId, !adUnitId.isEmpty else {
            onFailed?(VeonYandexSourceError.missingAdUnitId)
            return
        }
        
        bannerAdView = BannerAdView(adSize: yandexBannerSize())
        bannerAdView?.delegate = self
        bannerAdView?.translatesAutoresizingMaskIntoConstraints = false
        
        let request = AdRequest(adUnitID: adUnitId)
        bannerAdView?.loadAd(with: request)
    }

    func destroy() {
        bannerAdView?.delegate = nil
        bannerAdView?.removeFromSuperview()
        bannerAdView = nil

        onLoaded = nil
        onFailed = nil
    }
}

extension VeonYandexBannerSource: BannerAdViewDelegate {

    func viewControllerForPresentingModalView() -> UIViewController? {
        presentingViewController
    }

    func bannerAdViewDidLoad(_ bannerAdView: BannerAdView) {
        onLoaded?(bannerAdView)
    }

    func bannerAdViewDidFailLoading(_ bannerAdView: BannerAdView, error: Error) {
        onFailed?(error)
    }

    func bannerAdViewDidClick(_ bannerAdView: BannerAdView) {
        bannerDelegateForwarder?.bannerSourceDidRecordClick(sdk)
    }
    
    func bannerAdViewDidClose(_ bannerAdView: BannerAdView) {
        bannerDelegateForwarder?.bannerSourceDidDismissScreen(sdk)
    }

    func bannerAdView(_ bannerAdView: BannerAdView, didTrackImpression impressionData: (any ImpressionData)?) {
        bannerDelegateForwarder?.bannerSourceDidRecordImpression(sdk)
    }
}

enum VeonYandexSourceError: LocalizedError {
    case missingAdUnitId
    var errorDescription: String? { "Yandex ad unit id is missing." }
}
