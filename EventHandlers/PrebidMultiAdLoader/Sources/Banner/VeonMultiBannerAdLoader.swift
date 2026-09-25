//
//  VeonMultiBannerAdLoader.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//
import UIKit
import VeonPrebidRemoteConfig

/// Races Prebid / GAM / Yandex banner sources against each other, in the
/// order defined by `SdkConfigStore.priorityOrder`, and surfaces
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

    /// Handed to every banner source as `bannerDelegateForwarder` instead
    /// of `self`. `VeonBannerEventForwarding` is a public protocol, and a
    /// public type conforming to it would be forced to mark every method
    /// `public` — which would let app code holding a `VeonMultiBannerAdLoader`
    /// reference call `bannerSourceDidRecordImpression(_:)` etc. directly
    /// and forge engagement events. Routing through this private
    /// forwarder keeps those handlers off the public class entirely.
    private lazy var eventForwarder = BannerEventForwarder(owner: self)

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
        prebidSource.bannerDelegateForwarder = eventForwarder
        sources[.prebid] = AnyVeonAdSourceLoading(prebidSource)

        // refreshInterval is not used here; it is configured via AdManager.
        if let gamSource = VeonAdSourceRegistry.shared.makeBannerSource(
            for: .gam, adUnitId: gamAdUnitId, adSize: adSize, rootViewController: rootViewController
        ) {
            sources[.gam] = gamSource
            (gamSource.underlying as? VeonBannerSourceForwardable)?.bannerDelegateForwarder = eventForwarder
        }

        // refreshInterval is not used here;
        if let yandexSource = VeonAdSourceRegistry.shared.makeBannerSource(
            for: .yandex, adUnitId: yandexAdUnitId, adSize: adSize, rootViewController: rootViewController
        ) {
            sources[.yandex] = yandexSource
            (yandexSource.underlying as? VeonBannerSourceForwardable)?.bannerDelegateForwarder = eventForwarder
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

    // MARK: - Called only by BannerEventForwarder

    fileprivate func handleImpression(_ sdk: SdkType) {
        delegate?.bannerLoader(self, didRecordImpressionFrom: sdk)
    }

    fileprivate func handleClick(_ sdk: SdkType) {
        delegate?.bannerLoader(self, didRecordClickFrom: sdk)
    }

    fileprivate func handleWillLeaveApplication(_ sdk: SdkType) {
        delegate?.bannerLoader(self, willLeaveApplication: sdk)
    }

    fileprivate func handleWillPresentScreen(_ sdk: SdkType) {
        delegate?.bannerLoader(self, willPresentScreenFrom: sdk)
    }

    fileprivate func handleWillDismissScreen(_ sdk: SdkType) {
        delegate?.bannerLoader(self, willDismissScreenFrom: sdk)
    }

    fileprivate func handleDidDismissScreen(_ sdk: SdkType) {
        delegate?.bannerLoader(self, didDismissScreenFrom: sdk)
    }
}

/// Private conformer to `VeonBannerEventForwarding` on behalf of
/// `VeonMultiBannerAdLoader`. Because this type is `private`, Swift does
/// not require its protocol witnesses to be `public` even though
/// `VeonBannerEventForwarding` itself is a public protocol — the
/// conformance is only usable within this file, which is exactly where
/// it's assigned (`bannerDelegateForwarder = eventForwarder`).
private final class BannerEventForwarder: VeonBannerEventForwarding {

    private weak var owner: VeonMultiBannerAdLoader?

    init(owner: VeonMultiBannerAdLoader) {
        self.owner = owner
    }

    func bannerSourceDidRecordImpression(_ sdk: SdkType) {
        owner?.handleImpression(sdk)
    }

    func bannerSourceDidRecordClick(_ sdk: SdkType) {
        owner?.handleClick(sdk)
    }

    func bannerSourceWillLeaveApplication(_ sdk: SdkType) {
        owner?.handleWillLeaveApplication(sdk)
    }

    func bannerSourceWillPresentScreen(_ sdk: SdkType) {
        owner?.handleWillPresentScreen(sdk)
    }

    func bannerSourceWillDismissScreen(_ sdk: SdkType) {
        owner?.handleWillDismissScreen(sdk)
    }

    func bannerSourceDidDismissScreen(_ sdk: SdkType) {
        owner?.handleDidDismissScreen(sdk)
    }
}
