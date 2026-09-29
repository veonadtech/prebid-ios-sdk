//
// VeonAdRaceTests.swift
// PrebidMultiAdLoaderTests
//
// Copyright © Veon AdTech.
//

import XCTest
#if canImport(VeonPrebidMultiAdLoader)
@testable import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig
#else
@testable import PrebidMultiAdLoader
import PrebidRemoteConfig
#endif

/// Behaviour of the priority race: the first source *in priority order* that
/// has loaded wins, regardless of which source finishes first.
@MainActor
final class VeonAdRaceTests: XCTestCase {

    private var race: VeonAdRace<String>!
    private var sources: [SdkType: MockAdSource<String>] = [:]

    private var loadedEvents: [(ad: String, sdk: SdkType)] = []
    private var failedEvents: [(sdk: SdkType, error: Error?)] = []

    override func setUp() {
        super.setUp()
        race = nil
        sources = [:]
        loadedEvents = []
        failedEvents = []
    }

    override func tearDown() {
        race = nil
        sources = [:]
        super.tearDown()
    }

    // MARK: - Helpers

    /// Creates a race where every SDK in `available` has a mock source, and
    /// `priority` is the configured priority list (it may mention SDKs that
    /// have no source).
    private func makeRace(priority: [SdkType], available: [SdkType]? = nil) {
        let available = available ?? priority
        sources = [:]
        var wrapped: [SdkType: AnyVeonAdSourceLoading<String>] = [:]
        for sdk in available {
            let mock = MockAdSource<String>()
            sources[sdk] = mock
            wrapped[sdk] = AnyVeonAdSourceLoading(mock)
        }

        let race = VeonAdRace<String>(priorityOrder: priority, sources: wrapped)
        race.onLoaded = { [weak self] ad, sdk in
            self?.loadedEvents.append((ad, sdk))
        }
        race.onSourceFailed = { [weak self] sdk, error in
            self?.failedEvents.append((sdk, error))
        }
        self.race = race
    }

    private func source(_ sdk: SdkType, file: StaticString = #filePath, line: UInt = #line) -> MockAdSource<String> {
        guard let source = sources[sdk] else {
            XCTFail("No mock source for \(sdk)", file: file, line: line)
            return MockAdSource<String>()
        }
        return source
    }

    // MARK: - Setup

    func testInit_dropsSdksWithoutRegisteredSource() {
        makeRace(
            priority: [TestSdk.prebid, TestSdk.gam, TestSdk.yandex],
            available: [TestSdk.gam, TestSdk.yandex]
        )

        XCTAssertEqual(race.priorityOrder, [TestSdk.gam, TestSdk.yandex])
    }

    func testInit_keepsConfiguredPriorityOrder() {
        makeRace(priority: [TestSdk.yandex, TestSdk.gam, TestSdk.prebid])

        XCTAssertEqual(race.priorityOrder, [TestSdk.yandex, TestSdk.gam, TestSdk.prebid])
    }

    func testStart_loadsEverySourceExactlyOnce() {
        makeRace(priority: [TestSdk.prebid, TestSdk.gam, TestSdk.yandex])

        race.start()

        for sdk in [TestSdk.prebid, TestSdk.gam, TestSdk.yandex] {
            XCTAssertEqual(source(sdk).loadCount, 1, "\(sdk) should be loaded once")
        }
        XCTAssertTrue(loadedEvents.isEmpty)
    }

    func testStart_withoutSourcesDoesNothing() {
        makeRace(priority: [TestSdk.prebid, TestSdk.gam], available: [])

        race.start()

        XCTAssertTrue(race.priorityOrder.isEmpty)
        XCTAssertTrue(loadedEvents.isEmpty)
        XCTAssertTrue(failedEvents.isEmpty)
    }

    // MARK: - Winner selection

    func testHighestPriorityLoadedFirst_winsImmediately() {
        makeRace(priority: [TestSdk.prebid, TestSdk.gam])
        race.start()
        let gamDestroysBefore = source(TestSdk.gam).destroyCount
        let prebidDestroysBefore = source(TestSdk.prebid).destroyCount

        source(TestSdk.prebid).simulateLoaded("prebid-ad")

        XCTAssertEqual(loadedEvents.count, 1)
        XCTAssertEqual(loadedEvents.first?.ad, "prebid-ad")
        XCTAssertEqual(loadedEvents.first?.sdk, TestSdk.prebid)
        XCTAssertEqual(source(TestSdk.gam).destroyCount, gamDestroysBefore + 1, "the loser must be destroyed")
        XCTAssertEqual(source(TestSdk.prebid).destroyCount, prebidDestroysBefore, "the winner must stay alive")
    }

    func testLowerPriorityLoadedFirst_waitsForHigherPriority() {
        makeRace(priority: [TestSdk.prebid, TestSdk.gam])
        race.start()

        source(TestSdk.gam).simulateLoaded("gam-ad")
        XCTAssertTrue(loadedEvents.isEmpty, "GAM must not win while Prebid (higher priority) is still loading")

        source(TestSdk.prebid).simulateLoaded("prebid-ad")

        XCTAssertEqual(loadedEvents.count, 1)
        XCTAssertEqual(loadedEvents.first?.sdk, TestSdk.prebid)
        XCTAssertEqual(loadedEvents.first?.ad, "prebid-ad")
    }

    func testPriorityFromConfigIsRespected_notAlphabeticalOrDeclarationOrder() {
        makeRace(priority: [TestSdk.yandex, TestSdk.gam, TestSdk.prebid])
        race.start()

        source(TestSdk.prebid).simulateLoaded("prebid-ad")
        source(TestSdk.gam).simulateLoaded("gam-ad")
        XCTAssertTrue(loadedEvents.isEmpty)

        source(TestSdk.yandex).simulateLoaded("yandex-ad")

        XCTAssertEqual(loadedEvents.count, 1)
        XCTAssertEqual(loadedEvents.first?.sdk, TestSdk.yandex)
    }

    func testHigherPriorityFails_fallsBackToAlreadyLoadedLowerPriority() {
        makeRace(priority: [TestSdk.prebid, TestSdk.gam])
        race.start()
        source(TestSdk.gam).simulateLoaded("gam-ad")

        source(TestSdk.prebid).simulateFailure(MockAdError(code: 1))

        XCTAssertEqual(loadedEvents.count, 1)
        XCTAssertEqual(loadedEvents.first?.sdk, TestSdk.gam)
        XCTAssertEqual(loadedEvents.first?.ad, "gam-ad")
    }

    func testHigherPriorityFails_thenLowerPriorityLoadsLater() {
        makeRace(priority: [TestSdk.prebid, TestSdk.gam])
        race.start()

        source(TestSdk.prebid).simulateFailure()
        XCTAssertTrue(loadedEvents.isEmpty)

        source(TestSdk.gam).simulateLoaded("gam-ad")

        XCTAssertEqual(loadedEvents.count, 1)
        XCTAssertEqual(loadedEvents.first?.sdk, TestSdk.gam)
    }

    func testThreeSources_failureOfFirstPromotesNextLoadedInOrder() {
        makeRace(priority: [TestSdk.prebid, TestSdk.gam, TestSdk.yandex])
        race.start()
        source(TestSdk.yandex).simulateLoaded("yandex-ad")
        source(TestSdk.gam).simulateLoaded("gam-ad")
        XCTAssertTrue(loadedEvents.isEmpty)
        let yandexDestroysBefore = source(TestSdk.yandex).destroyCount

        source(TestSdk.prebid).simulateFailure()

        XCTAssertEqual(loadedEvents.count, 1)
        XCTAssertEqual(loadedEvents.first?.sdk, TestSdk.gam, "GAM is next in priority order and already loaded")
        XCTAssertEqual(source(TestSdk.yandex).destroyCount, yandexDestroysBefore + 1)
    }

    func testOnLoaded_firesOnlyOnce_evenIfLoserLoadsAfterwards() {
        makeRace(priority: [TestSdk.prebid, TestSdk.gam])
        race.start()

        source(TestSdk.prebid).simulateLoaded("prebid-ad")
        source(TestSdk.gam).simulateLoaded("gam-ad")

        XCTAssertEqual(loadedEvents.count, 1)
        XCTAssertEqual(loadedEvents.first?.sdk, TestSdk.prebid)
    }

    func testSingleSource_winsWhenLoaded() {
        makeRace(priority: [TestSdk.yandex])
        race.start()

        source(TestSdk.yandex).simulateLoaded("yandex-ad")

        XCTAssertEqual(loadedEvents.count, 1)
        XCTAssertEqual(loadedEvents.first?.sdk, TestSdk.yandex)
    }

    // MARK: - Failures

    func testAllSourcesFail_reportsEveryFailureAndNeverLoads() {
        makeRace(priority: [TestSdk.prebid, TestSdk.gam])
        race.start()

        source(TestSdk.gam).simulateFailure(MockAdError(code: 2))
        source(TestSdk.prebid).simulateFailure(MockAdError(code: 1))

        XCTAssertTrue(loadedEvents.isEmpty)
        XCTAssertEqual(failedEvents.map { $0.sdk }, [TestSdk.gam, TestSdk.prebid], "failures are reported in the order they happen")
        XCTAssertEqual(failedEvents.first?.error as? MockAdError, MockAdError(code: 2))
        XCTAssertEqual(failedEvents.last?.error as? MockAdError, MockAdError(code: 1))
        XCTAssertTrue(race.priorityOrder.isEmpty, "failed SDKs are removed from the priority order")
    }

    func testFailureWithoutError_isReportedWithNilError() {
        makeRace(priority: [TestSdk.gam])
        race.start()

        source(TestSdk.gam).simulateFailure(nil)

        XCTAssertEqual(failedEvents.count, 1)
        XCTAssertEqual(failedEvents.first?.sdk, TestSdk.gam)
        XCTAssertNil(failedEvents.first?.error)
    }

    func testFailureOfLowerPriority_doesNotDisturbPendingHigherPriority() {
        makeRace(priority: [TestSdk.prebid, TestSdk.gam])
        race.start()

        source(TestSdk.gam).simulateFailure()
        XCTAssertTrue(loadedEvents.isEmpty)

        source(TestSdk.prebid).simulateLoaded("prebid-ad")

        XCTAssertEqual(loadedEvents.count, 1)
        XCTAssertEqual(loadedEvents.first?.sdk, TestSdk.prebid)
    }

    // MARK: - Destroy

    func testDestroy_destroysEverySource() {
        makeRace(priority: [TestSdk.prebid, TestSdk.gam, TestSdk.yandex])
        race.start()
        let before = [TestSdk.prebid, TestSdk.gam, TestSdk.yandex].map { source($0).destroyCount }

        race.destroy()

        let after = [TestSdk.prebid, TestSdk.gam, TestSdk.yandex].map { source($0).destroyCount }
        XCTAssertEqual(after, before.map { $0 + 1 })
    }

    func testStart_afterDestroy_deliversNewWinner() {
        makeRace(priority: [TestSdk.prebid, TestSdk.gam])
        race.start()
        source(TestSdk.prebid).simulateLoaded("first")
        XCTAssertEqual(loadedEvents.count, 1)

        race.destroy()
        race.start()
        source(TestSdk.prebid).simulateLoaded("second")

        XCTAssertEqual(loadedEvents.map { $0.ad }, ["first", "second"])
    }
}
