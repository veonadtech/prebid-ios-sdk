//
//  VeonMultiBannerAdLoader.swift
//  PrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//
import UIKit
import VeonPrebidRemoteConfig

/// Races Prebid / GAM / Yandex banner sources against each other, in the
/// order defined by `VeonSdkConfigHolder.priorityOrder`, and surfaces
/// whichever loads first.
///
/// Prebid is always available (Core has a hard dependency on
/// `PrebidMobile`). GAM and Yandex are only in the race if the app has
/// linked the corresponding optional module and called its
/// `register()` — see `VeonAdSourceRegistry`. An SDK with no registered
/// factory is silently skipped, exactly like an SDK that failed to load.
///
/// Each source runs a fully independent ad request — there is no
/// cross-SDK targeting or bid sharing. This mirrors the Android
/// `MultiBannerLoaderLegacyGam` mediation component.
///
/// All public methods must be called on the main thread.
public final class VeonMultiBannerAdLoader {

    public weak var delegate: VeonMultiBannerAdLoaderDelegate?

    private let rootViewController: UIViewController?
    private let adSize: CGSize
    private let refreshInterval: TimeInterval?
    private let configId: String?
    private let gamAdUnitId: String?
    private let yandexAdUnitId: String?

    private var race: VeonAdRace<UIView>?
    private var failedCount = 0
    private var totalCount = 0

    public init(
        rootViewController: UIViewController?,
        adSize: CGSize,
        refreshInterval: TimeInterval?,
        configId: String?,
        gamAdUnitId: String?,
        yandexAdUnitId: String?
    ) {
        self.rootViewController = rootViewController
        self.adSize = adSize
        self.configId = configId
        self.refreshInterval = refreshInterval
        self.gamAdUnitId = gamAdUnitId
        self.yandexAdUnitId = yandexAdUnitId
    }

    public func loadAd() {
        destroy()

        var sources: [SdkType: AnyVeonAdSourceLoading<UIView>] = [:]

        let prebidSource = VeonPrebidBannerSource(configId: configId, adSize: adSize, refreshInterval: refreshInterval)
        prebidSource.presentingViewController = rootViewController
        prebidSource.bannerDelegateForwarder = self
        sources[.prebid] = AnyVeonAdSourceLoading(prebidSource)

        // refreshInterval is not used here; it is configured via AdManager.
        if let gamSource = VeonAdSourceRegistry.shared.makeBannerSource(
            for: .gam, adUnitId: gamAdUnitId, adSize: adSize, rootViewController: rootViewController
        ) {
            sources[.gam] = gamSource
            (gamSource.underlying as? VeonBannerSourceForwardable)?.bannerDelegateForwarder = self
        }

        // refreshInterval is not used here;
        if let yandexSource = VeonAdSourceRegistry.shared.makeBannerSource(
            for: .yandex, adUnitId: yandexAdUnitId, adSize: adSize, rootViewController: rootViewController
        ) {
            sources[.yandex] = yandexSource
            (yandexSource.underlying as? VeonBannerSourceForwardable)?.bannerDelegateForwarder = self
        }

        let priorityOrder = SdkConfigStore.priorityOrder
        totalCount = priorityOrder.filter { sources[$0] != nil }.count
        failedCount = 0

        let race = VeonAdRace(priorityOrder: priorityOrder, sources: sources)
        race.onLoaded = { [weak self] view, sdk in
            guard let self else { return }
            self.delegate?.bannerLoader(self, didLoad: view, from: sdk)
        }
        race.onSourceFailed = { [weak self] sdk, error in
            guard let self else { return }
            self.delegate?.bannerLoader(self, didFailToLoad: sdk, error: error)
            self.failedCount += 1
            if self.failedCount >= self.totalCount {
                self.delegate?.bannerLoaderDidFailAll(self)
            }
        }
        self.race = race
        race.start()
    }

    public func destroy() {
        race?.destroy()
        race = nil
    }
}

extension VeonMultiBannerAdLoader: VeonBannerEventForwarding {

    public func bannerSourceDidRecordImpression(_ sdk: SdkType) {
        delegate?.bannerLoader(self, didRecordImpressionFrom: sdk)
    }

    public func bannerSourceDidRecordClick(_ sdk: SdkType) {
        delegate?.bannerLoader(self, didRecordClickFrom: sdk)
    }

    public func bannerSourceWillLeaveApplication(_ sdk: SdkType) {
        delegate?.bannerLoader(self, willLeaveApplication: sdk)
    }

    public func bannerSourceWillPresentScreen(_ sdk: SdkType) {
        delegate?.bannerLoader(self, willPresentScreenFrom: sdk)
    }

    public func bannerSourceWillDismissScreen(_ sdk: SdkType) {
        delegate?.bannerLoader(self, willDismissScreenFrom: sdk)
    }

    public func bannerSourceDidDismissScreen(_ sdk: SdkType) {
        delegate?.bannerLoader(self, didDismissScreenFrom: sdk)
    }
}
