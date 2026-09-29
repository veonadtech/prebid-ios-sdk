//
// VeonMultiBannerAdLoaderTests.swift
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

/// End-to-end behaviour of `VeonMultiBannerAdLoader` with GAM and Yandex replaced by mocks.
///
/// The loader is created with `configId: nil`, so the built-in Prebid source fails
/// synchronously inside `loadAd()` (no PrebidMobile init, no network). That makes Prebid
/// the first reported failure in every race and leaves GAM / Yandex fully under test control.
@MainActor
final class VeonMultiBannerAdLoaderTests: XCTestCase {

    private let gamSources = SourceRecorder<MockBannerSource>()
    private let yandexSources = SourceRecorder<MockBannerSource>()

    private var delegate: BannerLoaderDelegateSpy!
    private var loader: VeonMultiBannerAdLoader!

    override func setUp() {
        super.setUp()
        delegate = BannerLoaderDelegateSpy()
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
        VeonAdSourceRegistry.shared.registerBannerSource(for: .gam) { _, _, _ in
            AnyVeonAdSourceLoading(gam.record(MockBannerSource(sdk: .gam)))
        }
        VeonAdSourceRegistry.shared.registerBannerSource(for: .yandex) { _, _, _ in
            AnyVeonAdSourceLoading(yandex.record(MockBannerSource(sdk: .yandex)))
        }
    }

    private func makeLoader(rootViewController: UIViewController? = nil) -> VeonMultiBannerAdLoader {
        let loader = VeonMultiBannerAdLoader(
            rootViewController: rootViewController,
            adSize: CGSize(width: 320, height: 50),
            refreshInterval: nil,
            configId: nil,
            gamAdUnitId: "gam-unit",
            yandexAdUnitId: "yandex-unit"
        )
        loader.delegate = delegate
        return loader
    }

    private var gam: MockBannerSource { gamSources.last }
    private var yandex: MockBannerSource { yandexSources.last }

    // MARK: - Race setup

    func testLoadAd_loadsGamAndYandexOnce_andReportsMissingPrebidConfigId() {
        loader.loadAd()

        XCTAssertEqual(gamSources.created.count, 1)
        XCTAssertEqual(yandexSources.created.count, 1)
        XCTAssertEqual(gam.loadCount, 1)
        XCTAssertEqual(yandex.loadCount, 1)
        XCTAssertEqual(delegate.events, [.didFailToLoad(.prebid)])
    }

    func testLoadAd_prebidFailureCarriesTheMissingConfigIdError() {
        loader.loadAd()

        XCTAssertEqual(delegate.loadFailures.count, 1)
        XCTAssertEqual(delegate.loadFailures.first?.sdk, .prebid)
        XCTAssertNotNil(delegate.loadFailures.first?.error)
    }

    func testLoadAd_passesAdUnitIdsSizeAndRootViewControllerToTheFactories() {
        let root = UIViewController()
        var gamArgs: (String?, CGSize, UIViewController?)?
        var yandexArgs: (String?, CGSize, UIViewController?)?
        let gam = gamSources
        let yandex = yandexSources
        VeonAdSourceRegistry.shared.registerBannerSource(for: .gam) { id, size, vc in
            gamArgs = (id, size, vc)
            return AnyVeonAdSourceLoading(gam.record(MockBannerSource(sdk: .gam)))
        }
        VeonAdSourceRegistry.shared.registerBannerSource(for: .yandex) { id, size, vc in
            yandexArgs = (id, size, vc)
            return AnyVeonAdSourceLoading(yandex.record(MockBannerSource(sdk: .yandex)))
        }
        loader = makeLoader(rootViewController: root)

        loader.loadAd()

        XCTAssertEqual(gamArgs?.0, "gam-unit")
        XCTAssertEqual(gamArgs?.1, CGSize(width: 320, height: 50))
        XCTAssertTrue(gamArgs?.2 === root)
        XCTAssertEqual(yandexArgs?.0, "yandex-unit")
        XCTAssertEqual(yandexArgs?.1, CGSize(width: 320, height: 50))
        XCTAssertTrue(yandexArgs?.2 === root)
    }

    func testLoadAd_handsTheEventForwarderToEverySource() {
        loader.loadAd()

        XCTAssertNotNil(gam.bannerDelegateForwarder)
        XCTAssertNotNil(yandex.bannerDelegateForwarder)
    }

    // MARK: - Winner selection

    func testHighestPrioritySourceWins() {
        loader.loadAd()
        let view = UIView()
        let yandexDestroysBefore = yandex.destroyCount

        gam.simulateLoaded(view)

        XCTAssertEqual(delegate.events, [.didFailToLoad(.prebid), .didLoad(.gam)])
        XCTAssertTrue(delegate.loadedViews.first === view)
        XCTAssertEqual(yandex.destroyCount, yandexDestroysBefore + 1, "the loser must be destroyed")
    }

    func testLowerPrioritySourceWaitsForHigherPriority_thenFallsBackWhenItFails() {
        loader.loadAd()

        yandex.simulateLoaded()
        XCTAssertEqual(delegate.events, [.didFailToLoad(.prebid)], "Yandex must wait for GAM")

        gam.simulateFailure()

        XCTAssertEqual(delegate.events, [.didFailToLoad(.prebid), .didFailToLoad(.gam), .didLoad(.yandex)])
    }

    func testPriorityIsReadFromTheConfigOnEveryLoadAd() {
        RemoteConfigTestSupport.loadConfig(priority: ["YANDEX", "GAM", "PREBID"])
        loader.loadAd()

        gam.simulateLoaded()
        XCTAssertEqual(delegate.events, [.didFailToLoad(.prebid)], "GAM is second in this config")

        yandex.simulateLoaded()
        XCTAssertEqual(delegate.events, [.didFailToLoad(.prebid), .didLoad(.yandex)])
    }

    func testSourceMissingFromTheConfiguredPriority_neverParticipates() {
        RemoteConfigTestSupport.loadConfig(priority: ["GAM", "PREBID"])
        loader.loadAd()

        XCTAssertEqual(gam.loadCount, 1)
        XCTAssertEqual(yandex.loadCount, 0, "Yandex is not in the configured priority, so it must not load")
    }

    // MARK: - Failures

    func testAllSourcesFail_reportsEachFailureThenFailAllExactlyOnce() {
        loader.loadAd()

        gam.simulateFailure()
        XCTAssertFalse(delegate.events.contains(.didFailAll))
        yandex.simulateFailure()

        XCTAssertEqual(
            delegate.events,
            [.didFailToLoad(.prebid), .didFailToLoad(.gam), .didFailToLoad(.yandex), .didFailAll]
        )
    }

    func testFailAll_isNotReportedWhenASourceWins() {
        loader.loadAd()

        gam.simulateLoaded()

        XCTAssertFalse(delegate.events.contains(.didFailAll))
    }

    // MARK: - Lifecycle

    func testDestroy_destroysSourcesAndStopsDeliveringEvents() {
        loader.loadAd()
        let destroysBefore = gam.destroyCount

        loader.destroy()
        gam.simulateLoaded()

        XCTAssertEqual(gam.destroyCount, destroysBefore + 1)
        XCTAssertEqual(delegate.events, [.didFailToLoad(.prebid)], "nothing may be delivered after destroy()")
    }

    func testDestroy_withoutLoadAdIsSafe() {
        loader.destroy()
        loader.destroy()

        XCTAssertTrue(delegate.events.isEmpty)
    }

    func testLoadAdTwice_destroysTheFirstRaceAndStartsAFreshOne() {
        loader.loadAd()
        let firstGam = gam
        let firstDestroysBefore = firstGam.destroyCount

        loader.loadAd()

        XCTAssertEqual(gamSources.created.count, 2)
        XCTAssertEqual(firstGam.destroyCount, firstDestroysBefore + 1)

        firstGam.simulateLoaded()
        XCTAssertFalse(delegate.events.contains(.didLoad(.gam)), "the stale race must not deliver")

        gam.simulateLoaded()
        XCTAssertEqual(delegate.events.filter { $0 == .didLoad(.gam) }.count, 1)
    }

    func testLoadAdTwice_afterAFailure_retriesEverySource() {
        loader.loadAd()
        gam.simulateFailure()

        loader.loadAd()

        XCTAssertEqual(gam.loadCount, 1, "the second race uses a new GAM source")
        XCTAssertEqual(gamSources.created.count, 2)
        gam.simulateLoaded()
        XCTAssertEqual(delegate.events.last, .didLoad(.gam))
    }

    // MARK: - Engagement events

    func testEngagementEvents_areForwardedFromTheSourceToTheDelegate() {
        loader.loadAd()
        gam.simulateLoaded()
        let before = delegate.events.count
        guard let forwarder = gam.bannerDelegateForwarder else {
            return XCTFail("The loader must hand its forwarder to the source")
        }

        forwarder.bannerSourceDidRecordImpression(.gam)
        forwarder.bannerSourceDidRecordClick(.gam)
        forwarder.bannerSourceWillLeaveApplication(.gam)
        forwarder.bannerSourceWillPresentScreen(.gam)
        forwarder.bannerSourceWillDismissScreen(.gam)
        forwarder.bannerSourceDidDismissScreen(.gam)

        XCTAssertEqual(Array(delegate.events.dropFirst(before)), [
            .impression(.gam),
            .click(.gam),
            .willLeaveApplication(.gam),
            .willPresentScreen(.gam),
            .willDismissScreen(.gam),
            .didDismissScreen(.gam)
        ])
    }

    func testEngagementEvents_carryTheSdkThatFiredThem() {
        loader.loadAd()

        yandex.bannerDelegateForwarder?.bannerSourceDidRecordClick(.yandex)
        gam.bannerDelegateForwarder?.bannerSourceDidRecordClick(.gam)

        XCTAssertEqual(Array(delegate.events.suffix(2)), [.click(.yandex), .click(.gam)])
    }

    func testEngagementEvents_areDroppedOnceTheLoaderIsGone() {
        loader.loadAd()
        let forwarder = gam.bannerDelegateForwarder
        let before = delegate.events.count

        loader = nil
        forwarder?.bannerSourceDidRecordClick(.gam)

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
    }
}
