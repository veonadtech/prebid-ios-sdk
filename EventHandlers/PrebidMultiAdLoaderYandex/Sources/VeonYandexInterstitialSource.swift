//
//  VeonYandexInterstitialSource.swift
//  PrebidMultiAdLoaderYandex
//
//  Copyright © Veon AdTech.
//

import Foundation
import UIKit
import YandexMobileAds
import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

final class VeonYandexInterstitialSource: NSObject, @MainActor VeonAdSourceLoading, VeonInterstitialSourceForwardable {

    typealias AdObject = VeonLoadedInterstitial

    var onLoaded: ((VeonLoadedInterstitial) -> Void)?
    var onFailed: ((Error?) -> Void)?

    weak var interstitialDelegateForwarder: VeonInterstitialEventForwarding?

    private let adUnitId: String?
    // Strong reference kept for the lifetime of this source, per Yandex's
    // recommendation to hold onto both the loader and the loaded ad.
    private lazy var interstitialAdLoader = InterstitialAdLoader()
    private var interstitialAd: InterstitialAd?

    init(adUnitId: String?) {
        self.adUnitId = adUnitId
        super.init()
    }

    func load() {
        guard let adUnitId, !adUnitId.isEmpty else {
            onFailed?(VeonYandexSourceError.missingAdUnitId)
            return
        }

        let request = AdRequest(adUnitID: adUnitId)
        interstitialAdLoader.loadAd(with: request) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let ad):
                self.interstitialAd = ad
                interstitialAd?.delegate = self
                self.onLoaded?(self)
            case .failure(let error):
                self.onFailed?(error)
            }
        }
    }

    @MainActor
    func destroy() {
        interstitialAd?.delegate = nil
        interstitialAd = nil
    }
}

extension VeonYandexInterstitialSource: InterstitialAdDelegate, @MainActor VeonLoadedInterstitial {

    var sdk: SdkType { .yandex }
    
    func interstitialAd(
        _ interstitialAd: YandexMobileAds.InterstitialAd,
        didTrackImpression impressionData: (any YandexMobileAds.ImpressionData)?
    ) {
        interstitialDelegateForwarder?.interstitialSourceDidTrackImpression(self)
    }

    @MainActor
    func show(from viewController: UIViewController) {
        interstitialAd?.show(from: viewController)
    }

    func interstitialAdDidShow(_ interstitialAd: YandexMobileAds.InterstitialAd) {
        interstitialDelegateForwarder?.interstitialSourceWillPresent(self)
    }

    func interstitialAdDidDismiss(_ interstitialAd: YandexMobileAds.InterstitialAd) {
        interstitialDelegateForwarder?.interstitialSourceDidDismiss(self)
    }

    func interstitialAd(_ interstitialAd: YandexMobileAds.InterstitialAd, didFailToShow error: any Error) {
        interstitialDelegateForwarder?.interstitialSourceDidFailToShow(self, error: error)
    }

    func interstitialAdDidClick(_ interstitialAd: InterstitialAd) {
        interstitialDelegateForwarder?.interstitialSourceDidClick(self)
    }
}
