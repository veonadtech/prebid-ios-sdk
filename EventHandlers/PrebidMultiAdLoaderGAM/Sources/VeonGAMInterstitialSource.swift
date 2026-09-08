//
//  VeonGAMInterstitialSource.swift
//  PrebidMultiAdLoaderGAM
//
//  Copyright © Veon AdTech.
//

import Foundation
import UIKit
import GoogleMobileAds
import VeonPrebidMultiAdLoader

final class VeonGAMInterstitialSource: NSObject, VeonAdSourceLoading {

    typealias AdObject = VeonLoadedInterstitial

    var onLoaded: ((VeonLoadedInterstitial) -> Void)?
    var onFailed: ((Error?) -> Void)?

    weak var interstitialDelegateForwarder: VeonInterstitialEventForwarding?

    private let adUnitId: String?
    private var interstitialAd: AdManagerInterstitialAd?

    init(adUnitId: String?) {
        self.adUnitId = adUnitId
    }

    func load() {
        guard let adUnitId, !adUnitId.isEmpty else {
            onFailed?(VeonGAMSourceError.missingAdUnitId)
            return
        }
        AdManagerInterstitialAd.load(with: adUnitId, request: AdManagerRequest()) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                self.onFailed?(error)
                return
            }
            guard let ad else {
                self.onFailed?(VeonGAMSourceError.missingAdUnitId)
                return
            }
            ad.fullScreenContentDelegate = self
            self.interstitialAd = ad
            self.onLoaded?(self)
        }
    }

    func destroy() {
        interstitialAd?.fullScreenContentDelegate = nil
        interstitialAd = nil
    }
}

extension VeonGAMInterstitialSource: FullScreenContentDelegate, VeonLoadedInterstitial {

    var sdk: VeonSdkType { .gam }

    func show(from viewController: UIViewController) {
        interstitialAd?.present(from: viewController)
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitialDelegateForwarder?.interstitialSourceWillPresent(self)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitialDelegateForwarder?.interstitialSourceDidDismiss(self)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitialDelegateForwarder?.interstitialSourceDidFailToShow(self, error: error)
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        interstitialDelegateForwarder?.interstitialSourceDidClick(self)
    }
}
