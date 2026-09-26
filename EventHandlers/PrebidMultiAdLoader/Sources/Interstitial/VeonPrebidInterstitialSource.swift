//
//  VeonPrebidInterstitialSource.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//

import UIKit
import PrebidMobile
import VeonPrebidRemoteConfig

final class VeonPrebidInterstitialSource: NSObject, VeonAdSourceLoading, VeonInterstitialSourceForwardable {

    typealias AdObject = VeonLoadedInterstitial

    var onLoaded: ((VeonLoadedInterstitial) -> Void)?
    var onFailed: ((Error?) -> Void)?

    weak var interstitialDelegateForwarder: VeonInterstitialEventForwarding?

    private let configId: String?
    private var adUnit: InterstitialRenderingAdUnit?

    init(configId: String?) {
        self.configId = configId
    }

    func load() {
        guard let configId, !configId.isEmpty else {
            onFailed?(VeonMultiAdLoaderError.missingConfigId(sdk: .prebid))
            return
        }
        let unit = InterstitialRenderingAdUnit(configID: configId, minSizePercentage: CGSize(width: 30, height: 30))
        unit.delegate = self
        adUnit = unit
        unit.loadAd()
    }

    func destroy() {
        adUnit?.delegate = nil
        adUnit = nil
    }
}

extension VeonPrebidInterstitialSource: InterstitialAdUnitDelegate, VeonLoadedInterstitial {

    var sdk: SdkType { .prebid }

    func show(from viewController: UIViewController) {
        adUnit?.show(from: viewController)
    }

    func interstitialDidReceiveAd(_ interstitial: InterstitialRenderingAdUnit) {
        onLoaded?(self)
    }

    func interstitial(_ interstitial: InterstitialRenderingAdUnit, didFailToReceiveAdWithError error: Error?) {
        onFailed?(error)
    }

    func interstitialDidClickAd(_ interstitial: InterstitialRenderingAdUnit) {
        interstitialDelegateForwarder?.interstitialSourceDidClick(self)
    }

    func interstitialWillPresentAd(_ interstitial: InterstitialRenderingAdUnit) {
        interstitialDelegateForwarder?.interstitialSourceWillPresent(self)
    }

    func interstitialDidDismissAd(_ interstitial: InterstitialRenderingAdUnit) {
        interstitialDelegateForwarder?.interstitialSourceDidDismiss(self)
    }
}
