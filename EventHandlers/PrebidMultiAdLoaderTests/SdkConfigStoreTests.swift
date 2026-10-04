//
// SdkConfigStoreTests.swift
// PrebidMultiAdLoaderTests
//
// Copyright © Veon AdTech.
//

import XCTest
@testable import VeonPrebidMultiAdLoader
@testable import VeonPrebidRemoteConfig

/// Every test loads its own config first — see `RemoteConfigHolderTests` for why.
final class SdkConfigStoreTests: XCTestCase {

    /// What `priorityOrder` returns when there is no usable config.
    /// NOTE: the doc comment on `SdkConfigStore.priorityOrder` says the fallback is
    /// Prebid-only (`[.prebid]`) but the code returns `[.yandex, .prebid, .gam]`.
    /// These tests pin the CODE; change this constant together with whichever of the two is wrong.
    private let fallbackOrder: [SdkType] = [.yandex, .prebid, .gam]

    func testPriorityOrder_followsTheConfiguredOrder() {
        RemoteConfigTestSupport.loadConfig(priority: ["GAM", "PREBID", "YANDEX"])

        XCTAssertEqual(SdkConfigStore.priorityOrder, [.gam, .prebid, .yandex])
    }

    func testPriorityOrder_canBeASubsetOfSdks() {
        RemoteConfigTestSupport.loadConfig(priority: ["YANDEX"])

        XCTAssertEqual(SdkConfigStore.priorityOrder, [.yandex])
    }

    func testPriorityOrder_emptyPriorityFallsBack() {
        RemoteConfigTestSupport.loadConfig(priority: [])

        XCTAssertEqual(SdkConfigStore.priorityOrder, fallbackOrder)
    }

    func testPriorityOrder_configWithWrongShapeFallsBack() {
        RemoteConfigTestSupport.load(json: "{}")

        XCTAssertNil(SdkConfigStore.config)
        XCTAssertEqual(SdkConfigStore.priorityOrder, fallbackOrder)
    }

    func testPriorityOrder_garbageBodyFallsBack() {
        RemoteConfigTestSupport.load(json: "not json at all")

        XCTAssertNil(SdkConfigStore.config)
        XCTAssertEqual(SdkConfigStore.priorityOrder, fallbackOrder)
    }

    func testPriorityOrder_unknownSdkInConfigFallsBack() {
        RemoteConfigTestSupport.loadConfig(priority: ["PREBID", "SOMETHING_NEW"])

        XCTAssertNil(SdkConfigStore.config)
        XCTAssertEqual(SdkConfigStore.priorityOrder, fallbackOrder)
    }

    func testPriorityOrder_reflectsTheLatestLoadedConfig() {
        RemoteConfigTestSupport.loadConfig(priority: ["GAM", "YANDEX"])
        XCTAssertEqual(SdkConfigStore.priorityOrder, [.gam, .yandex])

        RemoteConfigTestSupport.loadConfig(priority: ["YANDEX", "GAM"])
        XCTAssertEqual(SdkConfigStore.priorityOrder, [.yandex, .gam])
    }

    func testIsActive_reflectsTheMasterSwitch() {
        RemoteConfigTestSupport.loadConfig(priority: ["PREBID"], isActive: true)
        XCTAssertTrue(SdkConfigStore.isActive)

        RemoteConfigTestSupport.loadConfig(priority: ["PREBID"], isActive: false)
        XCTAssertFalse(SdkConfigStore.isActive)
    }

    func testIsActive_isFalseWithoutAUsableConfig() {
        RemoteConfigTestSupport.load(json: "{}")

        XCTAssertFalse(SdkConfigStore.isActive)
    }

    func testConfig_exposesTheDecodedSlice() {
        RemoteConfigTestSupport.loadConfig(priority: ["PREBID", "GAM"])

        XCTAssertEqual(SdkConfigStore.config?.priority, [.prebid, .gam])
        XCTAssertEqual(SdkConfigStore.config?.parsedSizes.count, 2)
    }
}
