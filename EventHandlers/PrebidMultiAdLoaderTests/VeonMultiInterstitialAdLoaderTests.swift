//
// VeonMultiInterstitialAdLoaderTests.swift
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

/// End-to-end behaviour of `VeonMultiInterstitialAdLoader` with GAM and Yandex replaced by mocks.
/// As in the banner tests, `configId: nil` makes the built-in Prebid source fail synchronously.
@MainActor
final class VeonMultiInterstitialAdLoaderTests: XCTestCase {

    private let gamSources = SourceRecorder<MockInterstitialSource>()
    private let yandexSources = SourceRecorder<MockInterstitialSource>()

    private var delegate: InterstitialLoaderDelegateSpy!
    private var loader: VeonMultiInterstitialAdLoader!

    override func setUp() {
        super.setUp()
        delegate = InterstitialLoaderDelegateSpy()
        registerMockFactories()
        RemoteConfigTestSupport.loadConfig(priority: ["GAM", "YANDEX", "PREBID"])
        loader = makeLoader()
    }

    override func tearDown() {
        loader?.destroy()
        loader = nil
        delegate = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func registerMockFactories() {
        let gam = gamSources
        let yandex = yandexSources
        VeonAdSourceRegistry.shared.registerInterstitialSource(for: .gam) { _ in
            AnyVeonAdSourceLoading(gam.record(MockInterstitialSource(sdk: .gam)))
        }
        VeonAdSourceRegistry.shared.registerInterstitialSource(for: .yandex) { _ in
            AnyVeonAdSourceLoading(yandex.record(MockInterstitialSource(sdk: .yandex)))
        }
    }

    private func makeLoader() -> VeonMultiInterstitialAdLoader {
        let loader = VeonMultiInterstitialAdLoader(configId: nil, gamAdUnitId: "gam-unit", yandexAdUnitId: "yandex-unit")
        loader.delegate = delegate
        return loader
    }

    private var gam: MockInterstitialSource { gamSources.last }
    private var yandex: MockInterstitialSource { yandexSources.last }

    // MARK: - Race setup

    func testInitialState_isNotReady() {
        XCTAssertFalse(loader.isReady)
    }

    func testLoadAd_loadsGamAndYandexOnce_andReportsMissingPrebidConfigId() {
        loader.loadAd()

        XCTAssertEqual(gam.loadCount, 1)
        XCTAssertEqual(yandex.loadCount, 1)
        XCTAssertEqual(delegate.events, [.didFailToLoad(.prebid)])
        XCTAssertFalse(loader.isReady)
    }

    func testLoadAd_passesAdUnitIdsToTheFactories() {
        var gamAdUnit: String??
        var yandexAdUnit: String??
        let gam = gamSources
        let yandex = yandexSources
        VeonAdSourceRegistry.shared.registerInterstitialSource(for: .gam) { id in
            gamAdUnit = .some(id)
            return AnyVeonAdSourceLoading(gam.record(MockInterstitialSource(sdk: .gam)))
        }
        VeonAdSourceRegistry.shared.registerInterstitialSource(for: .yandex) { id in
            yandexAdUnit = .some(id)
            return AnyVeonAdSourceLoading(yandex.record(MockInterstitialSource(sdk: .yandex)))
        }

        loader.loadAd()

        XCTAssertEqual(gamAdUnit, .some("gam-unit"))
        XCTAssertEqual(yandexAdUnit, .some("yandex-unit"))
    }

    func testLoadAd_handsTheEventForwarderToEverySource() {
        loader.loadAd()

        XCTAssertNotNil(gam.interstitialDelegateForwarder)
        XCTAssertNotNil(yandex.interstitialDelegateForwarder)
    }

    // MARK: - Winner selection

    func testHighestPrioritySourceWins_andBecomesReady() {
        loader.loadAd()

        gam.simulateLoaded()

        XCTAssertEqual(delegate.events, [.didFailToLoad(.prebid), .didLoad(.gam)])
        XCTAssertTrue(loader.isReady)
    }

    func testLowerPrioritySourceWaitsForHigherPriority_thenFallsBackWhenItFails() {
        loader.loadAd()

        yandex.simulateLoaded()
        XCTAssertFalse(loader.isReady, "Yandex must wait for GAM")

        gam.simulateFailure()

        XCTAssertTrue(loader.isReady)
        XCTAssertEqual(delegate.events, [.didFailToLoad(.prebid), .didFailToLoad(.gam), .didLoad(.yandex)])
    }

    func testPriorityIsReadFromTheConfigOnEveryLoadAd() {
        RemoteConfigTestSupport.loadConfig(priority: ["YANDEX", "GAM", "PREBID"])
        loader.loadAd()

        gam.simulateLoaded()
        XCTAssertFalse(loader.isReady)

        yandex.simulateLoaded()
        XCTAssertEqual(delegate.events.last, .didLoad(.yandex))
    }

    // MARK: - Failures

    func testAllSourcesFail_reportsEachFailureThenFailAllExactlyOnce() {
        loader.loadAd()

        gam.simulateFailure()
        yandex.simulateFailure()

        XCTAssertEqual(
            delegate.events,
            [.didFailToLoad(.prebid), .didFailToLoad(.gam), .didFailToLoad(.yandex), .didFailAll]
        )
        XCTAssertFalse(loader.isReady)
    }

    // MARK: - Showing

    func testShow_forwardsToTheWinningInterstitial() {
        loader.loadAd()
        gam.simulateLoaded()
        let presenter = UIViewController()

        loader.show(from: presenter)

        XCTAssertEqual(gam.loaded.showCount, 1)
        XCTAssertTrue(gam.loaded.lastPresenter === presenter)
        XCTAssertEqual(yandex.loaded.showCount, 0)
    }

    func testShow_whenNothingIsReadyDoesNothing() {
        loader.loadAd()

        loader.show(from: UIViewController())

        XCTAssertEqual(gam.loaded.showCount, 0)
        XCTAssertEqual(yandex.loaded.showCount, 0)
    }

    func testShow_afterDestroyDoesNothing() {
        loader.loadAd()
        gam.simulateLoaded()

        loader.destroy()
        loader.show(from: UIViewController())

        XCTAssertFalse(loader.isReady)
        XCTAssertEqual(gam.loaded.showCount, 0)
    }

    // MARK: - Lifecycle

    func testDestroy_destroysSourcesAndStopsDeliveringEvents() {
        loader.loadAd()
        let destroysBefore = gam.destroyCount

        loader.destroy()
        gam.simulateLoaded()

        XCTAssertEqual(gam.destroyCount, destroysBefore + 1)
        XCTAssertEqual(delegate.events, [.didFailToLoad(.prebid)])
        XCTAssertFalse(loader.isReady)
    }

    func testLoadAdTwice_discardsThePreviousWinner() {
        loader.loadAd()
        gam.simulateLoaded()
        XCTAssertTrue(loader.isReady)

        loader.loadAd()

        XCTAssertFalse(loader.isReady, "a new load must not keep showing the previous winner")
        XCTAssertEqual(gamSources.created.count, 2)
    }

    // MARK: - Lifecycle events forwarded from the winning source

    func testPresentationEvents_areForwardedWithTheSdkOfTheLoadedInterstitial() {
        loader.loadAd()
        gam.simulateLoaded()
        let before = delegate.events.count
        guard let forwarder = gam.interstitialDelegateForwarder else {
            return XCTFail("The loader must hand its forwarder to the source")
        }

        forwarder.interstitialSourceWillPresent(gam.loaded)
        forwarder.interstitialSourceDidTrackImpression(gam.loaded)
        forwarder.interstitialSourceDidClick(gam.loaded)

        XCTAssertEqual(Array(delegate.events.dropFirst(before)), [
            .willPresent(.gam),
            .didTrackImpression(.gam),
            .didClick(.gam)
        ])
        XCTAssertTrue(loader.isReady, "presenting/clicking must not consume the interstitial")
    }

    func testDidDismiss_isForwardedAndConsumesTheInterstitial() {
        loader.loadAd()
        yandex.simulateLoaded()
        gam.simulateFailure()
        XCTAssertTrue(loader.isReady)

        yandex.interstitialDelegateForwarder?.interstitialSourceDidDismiss(yandex.loaded)

        XCTAssertEqual(delegate.events.last, .didDismiss(.yandex))
        XCTAssertFalse(loader.isReady, "a dismissed interstitial cannot be shown again")
    }

    func testDidFailToShow_isForwardedAndConsumesTheInterstitial() {
        loader.loadAd()
        gam.simulateLoaded()

        gam.interstitialDelegateForwarder?.interstitialSourceDidFailToShow(gam.loaded, error: MockAdError(code: 7))

        XCTAssertEqual(delegate.events.last, .didFailToShow(.gam))
        XCTAssertFalse(loader.isReady)
    }

    func testForwardedEvents_areDroppedOnceTheLoaderIsGone() {
        loader.loadAd()
        gam.simulateLoaded()
        let forwarder = gam.interstitialDelegateForwarder
        let before = delegate.events.count

        loader = nil
        forwarder?.interstitialSourceDidClick(gam.loaded)

        XCTAssertEqual(delegate.events.count, before)
    }

    // MARK: - Nothing loadable

    /// Regression for the "loader never calls back" case: the remote priority only names SDKs
    /// whose optional module was never registered, so no source can take part in the race.
    func testLoadAd_whenNoConfiguredSdkCanLoad_reportsFailAllInsteadOfHanging() {
        VeonAdSourceRegistry.shared.removeAll()
        RemoteConfigTestSupport.loadConfig(priority: ["GAM", "YANDEX"])

        loader.loadAd()

        XCTAssertEqual(delegate.events, [.didFailAll])
        XCTAssertFalse(loader.isReady)
        XCTAssertTrue(gamSources.created.isEmpty)
        XCTAssertTrue(yandexSources.created.isEmpty)
    }

    func testLoadAd_whenOnlyPrebidCanLoad_reportsItsFailureThenFailAll() {
        VeonAdSourceRegistry.shared.removeAll()
        RemoteConfigTestSupport.loadConfig(priority: ["GAM", "YANDEX", "PREBID"])

        loader.loadAd()

        XCTAssertEqual(delegate.events, [.didFailToLoad(.prebid), .didFailAll])
    }

    func testLoadAd_afterNothingWasLoadable_aLaterLoadAdWithRegisteredSourcesWorks() {
        VeonAdSourceRegistry.shared.removeAll()
        RemoteConfigTestSupport.loadConfig(priority: ["GAM"])
        loader.loadAd()
        XCTAssertEqual(delegate.events, [.didFailAll])

        registerMockFactories()
        loader.loadAd()
        gam.simulateLoaded()

        XCTAssertEqual(delegate.events, [.didFailAll, .didLoad(.gam)])
        XCTAssertTrue(loader.isReady)
    }
}
