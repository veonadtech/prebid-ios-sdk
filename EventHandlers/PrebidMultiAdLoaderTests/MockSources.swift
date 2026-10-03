//
// MockSources.swift
// PrebidMultiAdLoaderTests
//
// Copyright © Veon AdTech.
//

import UIKit
import XCTest
#if canImport(VeonPrebidMultiAdLoader)
@testable import VeonPrebidMultiAdLoader
@testable import VeonPrebidRemoteConfig
#else
@testable import PrebidMultiAdLoader
@testable import PrebidRemoteConfig
#endif

// MARK: - Banner

/// Banner source that can receive the loader's event forwarder, like the real GAM/Yandex sources.
final class MockBannerSource: VeonAdSourceLoading, VeonBannerSourceForwardable {

    typealias AdObject = UIView

    let sdk: SdkType
    weak var bannerDelegateForwarder: VeonBannerEventForwarding?

    var onLoaded: ((UIView) -> Void)?
    var onFailed: ((Error?) -> Void)?

    private(set) var loadCount = 0
    private(set) var destroyCount = 0

    init(sdk: SdkType) {
        self.sdk = sdk
    }

    func load() { loadCount += 1 }
    func destroy() { destroyCount += 1 }

    func simulateLoaded(_ view: UIView = UIView()) { onLoaded?(view) }
    func simulateFailure(_ error: Error? = nil) { onFailed?(error) }
}

final class BannerLoaderDelegateSpy: VeonMultiBannerAdLoaderDelegate {

    enum Event: Equatable {
        case didLoad(SdkType)
        case didFailToLoad(SdkType)
        case didFailAll
        case impression(SdkType)
        case click(SdkType)
        case willLeaveApplication(SdkType)
        case willPresentScreen(SdkType)
        case willDismissScreen(SdkType)
        case didDismissScreen(SdkType)
    }

    private(set) var events: [Event] = []
    private(set) var loadedViews: [UIView] = []
    private(set) var loadFailures: [(sdk: SdkType, error: Error?)] = []

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didLoad view: UIView, from sdk: SdkType) {
        loadedViews.append(view)
        events.append(.didLoad(sdk))
    }

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didFailToLoad sdk: SdkType, error: Error?) {
        loadFailures.append((sdk, error))
        events.append(.didFailToLoad(sdk))
    }

    func bannerLoaderDidFailAll(_ loader: VeonMultiBannerAdLoader) {
        events.append(.didFailAll)
    }

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordImpressionFrom sdk: SdkType) {
        events.append(.impression(sdk))
    }

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordClickFrom sdk: SdkType) {
        events.append(.click(sdk))
    }

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willLeaveApplication sdk: SdkType) {
        events.append(.willLeaveApplication(sdk))
    }

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willPresentScreenFrom sdk: SdkType) {
        events.append(.willPresentScreen(sdk))
    }

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willDismissScreenFrom sdk: SdkType) {
        events.append(.willDismissScreen(sdk))
    }

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didDismissScreenFrom sdk: SdkType) {
        events.append(.didDismissScreen(sdk))
    }
}

// MARK: - Interstitial

final class MockLoadedInterstitial: VeonLoadedInterstitial {

    let sdk: SdkType
    private(set) var showCount = 0
    private(set) weak var lastPresenter: UIViewController?

    init(sdk: SdkType) {
        self.sdk = sdk
    }

    func show(from viewController: UIViewController) {
        showCount += 1
        lastPresenter = viewController
    }
}

final class MockInterstitialSource: VeonAdSourceLoading, VeonInterstitialSourceForwardable {

    typealias AdObject = VeonLoadedInterstitial

    /// The "ready to show" handle this source produces when it loads.
    let loaded: MockLoadedInterstitial
    weak var interstitialDelegateForwarder: VeonInterstitialEventForwarding?

    var onLoaded: ((VeonLoadedInterstitial) -> Void)?
    var onFailed: ((Error?) -> Void)?

    private(set) var loadCount = 0
    private(set) var destroyCount = 0

    init(sdk: SdkType) {
        loaded = MockLoadedInterstitial(sdk: sdk)
    }

    func load() { loadCount += 1 }
    func destroy() { destroyCount += 1 }

    func simulateLoaded() { onLoaded?(loaded) }
    func simulateFailure(_ error: Error? = nil) { onFailed?(error) }
}

final class InterstitialLoaderDelegateSpy: VeonMultiInterstitialAdLoaderDelegate {

    enum Event: Equatable {
        case didLoad(SdkType)
        case didFailToLoad(SdkType)
        case didFailAll
        case willPresent(SdkType)
        case didDismiss(SdkType)
        case didClick(SdkType)
        case didFailToShow(SdkType)
        case didTrackImpression(SdkType)
    }

    private(set) var events: [Event] = []

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didLoadFrom sdk: SdkType) {
        events.append(.didLoad(sdk))
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didFailToLoad sdk: SdkType, error: Error?) {
        events.append(.didFailToLoad(sdk))
    }

    func interstitialLoaderDidFailAll(_ loader: VeonMultiInterstitialAdLoader) {
        events.append(.didFailAll)
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, willPresent sdk: SdkType) {
        events.append(.willPresent(sdk))
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didDismiss sdk: SdkType) {
        events.append(.didDismiss(sdk))
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didClick sdk: SdkType) {
        events.append(.didClick(sdk))
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didFailToShow sdk: SdkType, error: Error?) {
        events.append(.didFailToShow(sdk))
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didTrackImpression sdk: SdkType) {
        events.append(.didTrackImpression(sdk))
    }
}
