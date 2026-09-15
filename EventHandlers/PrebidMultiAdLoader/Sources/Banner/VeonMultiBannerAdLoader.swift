//
//  VeonMultiBannerAdLoader.swift
//  PrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//

import Foundation
import UIKit
import VeonPrebidRemoteConfig

/// Receives events from a `VeonMultiBannerAdLoader` race.
public protocol VeonMultiBannerAdLoaderDelegate: AnyObject {
    /// The winning source loaded successfully. `view` has not been added
    /// to any view hierarchy yet — the delegate owns that.
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didLoad view: UIView, from sdk: SdkType)

    /// A single source failed and was removed from this race attempt.
    /// This can fire multiple times before `didLoad` or before every
    /// source has failed.
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didFailToLoad sdk: SdkType, error: Error?)

    /// Every source failed; no ad will be delivered for this `loadAd()` call.
    func bannerLoaderDidFailAll(_ loader: VeonMultiBannerAdLoader)
}

public extension VeonMultiBannerAdLoaderDelegate {
    func bannerLoaderDidFailAll(_ loader: VeonMultiBannerAdLoader) {}
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
    ///   - configId: Prebid Server stored impression config id.
    ///   - gamAdUnitId: GAM ad unit id. Ignored if the GAM module isn't registered.
    ///   - yandexAdUnitId: Yandex ad unit id. Ignored if the Yandex module isn't registered.
    public init(
        rootViewController: UIViewController?,
        adSize: CGSize,
        configId: String?,
        gamAdUnitId: String?,
        yandexAdUnitId: String?
    ) {
        self.rootViewController = rootViewController
        self.adSize = adSize
        self.configId = configId
        self.gamAdUnitId = gamAdUnitId
        self.yandexAdUnitId = yandexAdUnitId
    }

    public func loadAd() {
        destroy()

        var sources: [SdkType: AnyVeonAdSourceLoading<UIView>] = [:]

        let prebidSource = VeonPrebidBannerSource(configId: configId, adSize: adSize)
        prebidSource.presentingViewController = rootViewController
        sources[.prebid] = AnyVeonAdSourceLoading(prebidSource)

        if let gamSource = VeonAdSourceRegistry.shared.makeBannerSource(
            for: .gam, adUnitId: gamAdUnitId, adSize: adSize, rootViewController: rootViewController
        ) {
            sources[.gam] = gamSource
        }

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
