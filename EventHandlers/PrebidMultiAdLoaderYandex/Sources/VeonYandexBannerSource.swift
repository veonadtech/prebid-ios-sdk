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
final class VeonYandexBannerSource: NSObject, VeonAdSourceLoading {

    typealias AdObject = UIView

    var onLoaded: ((UIView) -> Void)?
    var onFailed: ((Error?) -> Void)?

    private let adUnitId: String?
    private let adSize: CGSize
    
    private lazy var bannerAdView: BannerAdView = {
        let bannerAdView = BannerAdView(adSize: yandexBannerSize())
        bannerAdView.delegate = self
        bannerAdView.translatesAutoresizingMaskIntoConstraints = false
        return bannerAdView
    }()

    init(adUnitId: String?, adSize: CGSize) {
        self.adUnitId = adUnitId
        self.adSize = adSize
    }

    /// Override point if you need a different CGSize -> BannerAdSize mapping
    /// (mirrors the `open` hook on the Android `MultiBannerLoaderLegacyGam`).
    func yandexBannerSize() -> BannerAdSize {
        BannerAdSize.inline(width: adSize.width, maxHeight: adSize.height)
    }

    func load() {
        guard let adUnitId, !adUnitId.isEmpty else {
            onFailed?(VeonYandexSourceError.missingAdUnitId)
            return
        }
        
        let request = AdRequest(adUnitID: adUnitId)
                bannerAdView.loadAd(with: request)
    }

    func destroy() {
        bannerAdView.delegate = nil
    }
}

extension VeonYandexBannerSource: BannerAdViewDelegate {
    func bannerAdView(_ bannerAdView: YandexMobileAds.BannerAdView, didTrackImpression impressionData: (any YandexMobileAds.ImpressionData)?) {
        print("Yandex didTrackImpression, impressionData: \(impressionData?.rawData ?? "nil")")
    }
    
    func bannerAdViewDidClick(_ bannerAdView: YandexMobileAds.BannerAdView) {
        print("Yandex bannerAdViewDidClick")
    }
    

    func bannerAdViewDidLoad(_ bannerAdView: BannerAdView) {
        onLoaded?(bannerAdView)
    }
    
    func bannerAdViewDidFailLoading(_ bannerAdView: BannerAdView, error: Error) {
        onFailed?(error)
    }
    
}

enum VeonYandexSourceError: LocalizedError {
    case missingAdUnitId
    var errorDescription: String? { "Yandex ad unit id is missing." }
}
