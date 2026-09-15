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
        loader.delegate = self
    }

    func load() {
        guard let adUnitId, !adUnitId.isEmpty else {
            onFailed?(VeonYandexSourceError.missingAdUnitId)
            return
        }
        let requestConfiguration = AdRequestConfiguration(adUnitID: adUnitId)
        loader.loadAd(with: requestConfiguration)
    }

    @MainActor func destroy() {
        interstitialAd?.delegate = nil
        interstitialAd = nil
    }
}

// MARK: - InterstitialAdLoaderDelegate (7.x API)
extension VeonYandexInterstitialSource: InterstitialAdLoaderDelegate {
    
    func interstitialAdLoader(_ adLoader: InterstitialAdLoader, didLoad interstitialAd: InterstitialAd) {
        interstitialAd.delegate = self
        self.interstitialAd = interstitialAd
        self.onLoaded?(self)
    }

    func interstitialAdLoader(_ adLoader: InterstitialAdLoader, didFailToLoadWithError requestError: AdRequestError) {
        onFailed?(requestError.error)
    }
}

extension VeonYandexInterstitialSource: InterstitialAdDelegate, VeonLoadedInterstitial {
    
    var sdk: SdkType { .yandex }
    
    func interstitialAd(_ interstitialAd: YandexMobileAds.InterstitialAd, didTrackImpression impressionData: (any YandexMobileAds.ImpressionData)?) {
        
        print("Interstitial ad impression tracked successfully, /(")
    }

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
