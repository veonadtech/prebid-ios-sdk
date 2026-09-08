//
//  VeonAdSourceRegistry.swift
//  PrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//
//  This is the extension point that makes GAM/Yandex support truly
//  optional, for both CocoaPods and SPM: Core never imports
//  GoogleMobileAds or YandexMobileAds, and never hardcodes their source
//  classes. Instead, the optional PrebidMultiAdLoaderGAM /
//  PrebidMultiAdLoaderYandex modules register a factory here, once, at
//  app startup. If a factory for a given VeonSdkType was never
//  registered (because the app never linked/called that optional
//  module), VeonMultiBannerAdLoader / VeonMultiInterstitialAdLoader
//  simply skip that SDK in the race — same as if it had failed to load.
//

import Foundation
import UIKit

/// Thread-safe registry of banner/interstitial source factories, keyed
/// by `VeonSdkType`. Populated by optional feature modules (see
/// `VeonGAMAdSourceProvider.register()` / `VeonYandexAdSourceProvider.register()`),
/// read by `VeonMultiBannerAdLoader` / `VeonMultiInterstitialAdLoader`.
public final class VeonAdSourceRegistry {

    public static let shared = VeonAdSourceRegistry()

    public typealias BannerFactory = (
        _ adUnitId: String?,
        _ adSize: CGSize,
        _ rootViewController: UIViewController?
    ) -> AnyVeonAdSourceLoading<UIView>

    public typealias InterstitialFactory = (
        _ adUnitId: String?
    ) -> AnyVeonAdSourceLoading<VeonLoadedInterstitial>

    private let lock = NSLock()
    private var bannerFactories: [VeonSdkType: BannerFactory] = [:]
    private var interstitialFactories: [VeonSdkType: InterstitialFactory] = [:]

    private init() {}

    /// Called by an optional module (e.g. `VeonGAMAdSourceProvider`) to make
    /// itself available to the banner race. Call once, e.g. right next to
    /// `Prebid.initializeSDK(...)` at app startup.
    public func registerBannerSource(for sdk: VeonSdkType, factory: @escaping BannerFactory) {
        lock.lock(); defer { lock.unlock() }
        bannerFactories[sdk] = factory
    }

    /// Same as `registerBannerSource`, for interstitials.
    public func registerInterstitialSource(for sdk: VeonSdkType, factory: @escaping InterstitialFactory) {
        lock.lock(); defer { lock.unlock() }
        interstitialFactories[sdk] = factory
    }

    func makeBannerSource(
        for sdk: VeonSdkType,
        adUnitId: String?,
        adSize: CGSize,
        rootViewController: UIViewController?
    ) -> AnyVeonAdSourceLoading<UIView>? {
        lock.lock(); let factory = bannerFactories[sdk]; lock.unlock()
        return factory?(adUnitId, adSize, rootViewController)
    }

    func makeInterstitialSource(for sdk: VeonSdkType, adUnitId: String?) -> AnyVeonAdSourceLoading<VeonLoadedInterstitial>? {
        lock.lock(); let factory = interstitialFactories[sdk]; lock.unlock()
        return factory?(adUnitId)
    }
}
