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

final class VeonYandexInterstitialSource: NSObject, VeonAdSourceLoading {

    typealias AdObject = VeonLoadedInterstitial

    var onLoaded: ((VeonLoadedInterstitial) -> Void)?
    var onFailed: ((Error?) -> Void)?

    weak var interstitialDelegateForwarder: VeonInterstitialEventForwarding?

    private let adUnitId: String?
    private let loader = InterstitialAdLoader()
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
        loader.loadAd(with: request) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let ad):
                ad.delegate = self
                self.interstitialAd = ad
                self.onLoaded?(self)
            case .failure(let error):
                self.onFailed?(error)
            }
        }
    }

    @MainActor func destroy() {
        interstitialAd?.delegate = nil
        interstitialAd = nil
    }
}

extension VeonYandexInterstitialSource: InterstitialAdDelegate, VeonLoadedInterstitial {
    func interstitialAd(_ interstitialAd: YandexMobileAds.InterstitialAd, didTrackImpression impressionData: (any YandexMobileAds.ImpressionData)?) {
        
        print("Interstitial ad impression tracked successfully, /(")
    }
    

    var sdk: VeonSdkType { .yandex }

    @MainActor func show(from viewController: UIViewController) {
        interstitialAd?.show(from: viewController)
    }

    func interstitialAdDidShow(_ interstitialAd: InterstitialAd) {
        interstitialDelegateForwarder?.interstitialSourceWillPresent(self)
    }

    func interstitialAdDidDismiss(_ interstitialAd: InterstitialAd) {
        interstitialDelegateForwarder?.interstitialSourceDidDismiss(self)
    }

    func interstitialAd(_ interstitialAd: InterstitialAd, didFailToShow error: Error) {
        interstitialDelegateForwarder?.interstitialSourceDidFailToShow(self, error: error)
    }

    func interstitialAdDidClick(_ interstitialAd: InterstitialAd) {
        interstitialDelegateForwarder?.interstitialSourceDidClick(self)
    }
}
