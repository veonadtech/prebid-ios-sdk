//
//  VeonMultiBannerAdLoader.swift
//  PrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//
import UIKit
import VeonPrebidRemoteConfig

/// Receives events from a `VeonMultiBannerAdLoader` race.
public protocol VeonMultiBannerAdLoaderDelegate: AnyObject {
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didLoad view: UIView, from sdk: SdkType)
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didFailToLoad sdk: SdkType, error: Error?)
    func bannerLoaderDidFailAll(_ loader: VeonMultiBannerAdLoader)

    // New, all with no-op defaults below so existing conformers don't break.
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordImpressionFrom sdk: SdkType)
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordClickFrom sdk: SdkType)
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willLeaveApplication sdk: SdkType)
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willPresentScreenFrom sdk: SdkType)
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willDismissScreenFrom sdk: SdkType)
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didDismissScreenFrom sdk: SdkType)
}

public extension VeonMultiBannerAdLoaderDelegate {
    func bannerLoaderDidFailAll(_ loader: VeonMultiBannerAdLoader) {}
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordImpressionFrom sdk: SdkType) {}
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordClickFrom sdk: SdkType) {}
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willPresentScreenFrom sdk: SdkType) {}
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willLeaveApplication sdk: SdkType) {}
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willDismissScreenFrom sdk: SdkType) {}
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didDismissScreenFrom sdk: SdkType) {}
}

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

    /// - Parameters:
    ///   - rootViewController: Used by the Prebid source to present modal
    ///     content on click, and passed through to any registered GAM/Yandex
    ///     source as their ad request's root view controller.
    ///   - adSize: Requested banner size, shared across all sources.
    ///   - refreshInterval: Delay (in seconds) for which to wait before performing an auto refresh.
    ///   - configId: Prebid Server stored impression config id.
    ///   - gamAdUnitId: GAM ad unit id. Ignored if the GAM module isn't registered.
    ///   - yandexAdUnitId: Yandex ad unit id. Ignored if the Yandex module isn't registered.
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
        sources[.prebid] = AnyVeonAdSourceLoading(prebidSource)

        // refreshInterval is not used here; it is configured via AdManager.
        if let gamSource = VeonAdSourceRegistry.shared.makeBannerSource(
            for: .gam, adUnitId: gamAdUnitId, adSize: adSize, rootViewController: rootViewController
        ) {
            sources[.gam] = gamSource
        }

        // refreshInterval is not used here;
        if let yandexSource = VeonAdSourceRegistry.shared.makeBannerSource(
            for: .yandex, adUnitId: yandexAdUnitId, adSize: adSize, rootViewController: rootViewController
        ) {
            sources[.yandex] = yandexSource
        }

        let priorityOrder = SdkConfigStore.priorityOrder
        totalCount = priorityOrder.filter { sources[$0] != nil }.count
        failedCount = 0

        let race = VeonAdRace(priorityOrder: priorityOrder, sources: sources)
        race.onLoaded = { [weak self] view, sdk in
            guard let self else { return }
            self.delegate?.bannerLoader(self, didLoad: view, from: sdk)

            if let engagementSource = sources[sdk]?.underlying as? VeonAdSourceEngagementReporting {
                engagementSource.onImpressionRecorded = { [weak self] in
                    guard let self else { return }
                    self.delegate?.bannerLoader(self, didRecordImpressionFrom: sdk)
                }
                engagementSource.onClickRecorded = { [weak self] in
                    guard let self else { return }
                    self.delegate?.bannerLoader(self, didRecordClickFrom: sdk)
                }
                engagementSource.onScreenWillPresent = { [weak self] in
                    guard let self else { return }
                    self.delegate?.bannerLoader(self, willPresentScreenFrom: sdk)
                }
                engagementSource.onScreenWillDismiss = { [weak self] in
                    guard let self else { return }
                    self.delegate?.bannerLoader(self, willDismissScreenFrom: sdk)
                }
                engagementSource.onWillLeaveApplication = { [weak self] in
                    guard let self else { return }
                    self.delegate?.bannerLoader(self, willLeaveApplication: sdk)
                }
                engagementSource.onScreenDidDismiss = { [weak self] in
                    guard let self else { return }
                    self.delegate?.bannerLoader(self, didDismissScreenFrom: sdk)
                }
            }
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
