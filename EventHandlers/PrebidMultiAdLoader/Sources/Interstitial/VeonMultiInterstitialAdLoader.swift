//
//  VeonMultiInterstitialAdLoader.swift
//  PrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//

import UIKit
import VeonPrebidRemoteConfig

/// Races Prebid / GAM / Yandex interstitial sources against each other,
/// in the order defined by `VeonSdkConfigHolder.priorityOrder`.
///
/// GAM and Yandex only participate if the app has linked the
/// corresponding optional module and called its `register()` — see
/// `VeonAdSourceRegistry`.
///
/// Unlike `VeonMultiBannerAdLoader`, the winning ad is not surfaced
/// automatically — call `show(from:)` when you're ready to present it
/// (e.g. at a natural pause point in the app).
///
/// All public methods must be called on the main thread.
public final class VeonMultiInterstitialAdLoader {

    public weak var delegate: VeonMultiInterstitialAdLoaderDelegate?

    private let configId: String?
    private let gamAdUnitId: String?
    private let yandexAdUnitId: String?

    private var race: VeonAdRace<VeonLoadedInterstitial>?
    private var winningInterstitial: VeonLoadedInterstitial?
    private var failedCount = 0
    private var totalCount = 0

    public init(configId: String?, gamAdUnitId: String?, yandexAdUnitId: String?) {
        self.configId = configId
        self.gamAdUnitId = gamAdUnitId
        self.yandexAdUnitId = yandexAdUnitId
    }

    public var isReady: Bool {
        winningInterstitial != nil
    }

    public func loadAd() {
        destroy()

        var sources: [SdkType: AnyVeonAdSourceLoading<VeonLoadedInterstitial>] = [:]

        let prebidSource = VeonPrebidInterstitialSource(configId: configId)
        let prebidWrapped = AnyVeonAdSourceLoading(prebidSource)
        sources[.prebid] = prebidWrapped
        (prebidWrapped.underlying as? VeonInterstitialSourceForwardable)?.interstitialDelegateForwarder = self

        if let gamSource = VeonAdSourceRegistry.shared.makeInterstitialSource(for: .gam, adUnitId: gamAdUnitId) {
            sources[.gam] = gamSource
            (gamSource.underlying as? VeonInterstitialSourceForwardable)?.interstitialDelegateForwarder = self
        }

        if let yandexSource = VeonAdSourceRegistry.shared.makeInterstitialSource(for: .yandex, adUnitId: yandexAdUnitId) {
            sources[.yandex] = yandexSource
            (yandexSource.underlying as? VeonInterstitialSourceForwardable)?.interstitialDelegateForwarder = self
        }

        let priorityOrder = SdkConfigStore.priorityOrder
        totalCount = priorityOrder.filter { sources[$0] != nil }.count
        failedCount = 0

        let race = VeonAdRace(priorityOrder: priorityOrder, sources: sources)
        race.onLoaded = { [weak self] interstitial, sdk in
            guard let self else { return }
            self.winningInterstitial = interstitial
            self.delegate?.interstitialLoader(self, didLoadFrom: sdk)
        }
        race.onSourceFailed = { [weak self] sdk, error in
            guard let self else { return }
            self.delegate?.interstitialLoader(self, didFailToLoad: sdk, error: error)
            self.failedCount += 1
            if self.failedCount >= self.totalCount {
                self.delegate?.interstitialLoaderDidFailAll(self)
            }
        }
        self.race = race
        race.start()
    }

    public func show(from viewController: UIViewController) {
        winningInterstitial?.show(from: viewController)
    }

    public func destroy() {
        race?.destroy()
        race = nil
        winningInterstitial = nil
    }
}

extension VeonMultiInterstitialAdLoader: VeonInterstitialEventForwarding {

    public func interstitialSourceWillPresent(_ source: VeonLoadedInterstitial) {
        delegate?.interstitialLoader(self, willPresent: source.sdk)
    }

    public func interstitialSourceDidDismiss(_ source: VeonLoadedInterstitial) {
        delegate?.interstitialLoader(self, didDismiss: source.sdk)
        winningInterstitial = nil
    }

    public func interstitialSourceDidClick(_ source: VeonLoadedInterstitial) {
        delegate?.interstitialLoader(self, didClick: source.sdk)
    }

    public func interstitialSourceDidFailToShow(_ source: VeonLoadedInterstitial, error: Error?) {
        delegate?.interstitialLoader(self, didFailToShow: source.sdk, error: error)
        winningInterstitial = nil
    }

    public func interstitialSourceDidTrackImpression(_ source: VeonLoadedInterstitial) {
        delegate?.interstitialLoader(self, didTrackImpression: source.sdk)
    }
}
