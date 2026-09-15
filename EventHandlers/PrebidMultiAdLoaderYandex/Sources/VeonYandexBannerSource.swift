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
    
    private var adView: AdView?

    init(adUnitId: String?, adSize: CGSize) {
        self.adUnitId = adUnitId
        self.adSize = adSize
    }

    /// Override point if you need a different CGSize -> BannerAdSize mapping
    /// (mirrors the `open` hook on the Android `MultiBannerLoaderLegacyGam`).
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
    }    
}

extension VeonYandexBannerSource: AdViewDelegate {
    
    func adView(_ adView: AdView, didTrackImpression impressionData: (any ImpressionData)?) {
        print("Yandex didTrackImpression, impressionData: \(impressionData?.rawData ?? "nil")")
    }
    
    func adViewDidClick(_ adView: AdView) {
        print("Yandex adViewDidClick")
    }
    
    func adViewDidLoad(_ adView: AdView) {
        onLoaded?(adView)
    }
    
    func adViewDidFailLoading(_ adView: AdView, error: Error) {
        onFailed?(error)
    }
}

enum VeonYandexSourceError: LocalizedError {
    case missingAdUnitId
    var errorDescription: String? { "Yandex ad unit id is missing." }
}
