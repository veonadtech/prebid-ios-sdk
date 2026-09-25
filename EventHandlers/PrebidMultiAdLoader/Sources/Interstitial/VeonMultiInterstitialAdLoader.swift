//
//  VeonMultiInterstitialAdLoader.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//

import UIKit
import VeonPrebidRemoteConfig

/// Races Prebid / GAM / Yandex interstitial sources against each other,
/// in the order defined by `SdkConfigStore.priorityOrder`.
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

    /// Handed to every interstitial source as `interstitialDelegateForwarder`
    /// instead of `self` — see the identical comment on
    /// `VeonMultiBannerAdLoader.eventForwarder`.
    private lazy var eventForwarder = InterstitialEventForwarder(owner: self)

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
        (prebidWrapped.underlying as? VeonInterstitialSourceForwardable)?.interstitialDelegateForwarder = eventForwarder

        if let gamSource = VeonAdSourceRegistry.shared.makeInterstitialSource(for: .gam, adUnitId: gamAdUnitId) {
            sources[.gam] = gamSource
            (gamSource.underlying as? VeonInterstitialSourceForwardable)?.interstitialDelegateForwarder = eventForwarder
        }

        if let yandexSource = VeonAdSourceRegistry.shared.makeInterstitialSource(for: .yandex, adUnitId: yandexAdUnitId) {
            sources[.yandex] = yandexSource
            (yandexSource.underlying as? VeonInterstitialSourceForwardable)?.interstitialDelegateForwarder = eventForwarder
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

    // MARK: - Called only by InterstitialEventForwarder

    fileprivate func handleWillPresent(_ sdk: SdkType) {
        delegate?.interstitialLoader(self, willPresent: sdk)
    }

    fileprivate func handleDidDismiss(_ sdk: SdkType) {
        delegate?.interstitialLoader(self, didDismiss: sdk)
        winningInterstitial = nil
    }

    fileprivate func handleDidClick(_ sdk: SdkType) {
        delegate?.interstitialLoader(self, didClick: sdk)
    }

    fileprivate func handleDidFailToShow(_ sdk: SdkType, error: Error?) {
        delegate?.interstitialLoader(self, didFailToShow: sdk, error: error)
        winningInterstitial = nil
    }

    fileprivate func handleDidTrackImpression(_ sdk: SdkType) {
        delegate?.interstitialLoader(self, didTrackImpression: sdk)
    }
}

/// Private conformer to `VeonInterstitialEventForwarding` on behalf of
/// `VeonMultiInterstitialAdLoader` — see `BannerEventForwarder` for why
/// this indirection exists.
private final class InterstitialEventForwarder: VeonInterstitialEventForwarding {

    private weak var owner: VeonMultiInterstitialAdLoader?

    init(owner: VeonMultiInterstitialAdLoader) {
        self.owner = owner
    }

    func interstitialSourceWillPresent(_ source: VeonLoadedInterstitial) {
        owner?.handleWillPresent(source.sdk)
    }

    func interstitialSourceDidDismiss(_ source: VeonLoadedInterstitial) {
        owner?.handleDidDismiss(source.sdk)
    }

    func interstitialSourceDidClick(_ source: VeonLoadedInterstitial) {
        owner?.handleDidClick(source.sdk)
    }

    func interstitialSourceDidFailToShow(_ source: VeonLoadedInterstitial, error: Error?) {
        owner?.handleDidFailToShow(source.sdk, error: error)
    }

    func interstitialSourceDidTrackImpression(_ source: VeonLoadedInterstitial) {
        owner?.handleDidTrackImpression(source.sdk)
    }
}
