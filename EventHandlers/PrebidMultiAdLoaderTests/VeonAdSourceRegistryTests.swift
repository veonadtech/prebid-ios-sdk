//
// VeonAdSourceRegistryTests.swift
// PrebidMultiAdLoaderTests
//
// Copyright © Veon AdTech.
//

import UIKit
import XCTest
#if canImport(VeonPrebidMultiAdLoader)
@testable import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig
#else
@testable import PrebidMultiAdLoader
import PrebidRemoteConfig
#endif

/// `VeonAdSourceRegistry.shared` is a process-wide singleton without a reset
/// API, so every test registers (and therefore overrides) exactly what it
/// asserts on and never relies on "nothing is registered yet".
@MainActor
final class VeonAdSourceRegistryTests: XCTestCase {

    private let registry = VeonAdSourceRegistry.shared

    // MARK: - Banner

    func testBanner_registeredFactoryReceivesArgumentsAndIsUsed() {
        let mock = MockAdSource<UIView>()
        let rootViewController = UIViewController()
        var receivedAdUnitId: String??
        var receivedSize: CGSize?
        var receivedRoot: UIViewController??

        registry.registerBannerSource(for: TestSdk.gam) { adUnitId, size, root in
            receivedAdUnitId = .some(adUnitId)
            receivedSize = size
            receivedRoot = .some(root)
            return AnyVeonAdSourceLoading(mock)
        }

        let source = registry.makeBannerSource(
            for: TestSdk.gam,
            adUnitId: "/1234/banner",
            adSize: CGSize(width: 320, height: 50),
            rootViewController: rootViewController
        )

        XCTAssertNotNil(source)
        XCTAssertTrue(source?.underlying === mock)
        XCTAssertEqual(receivedAdUnitId, .some("/1234/banner"))
        XCTAssertEqual(receivedSize, CGSize(width: 320, height: 50))
        XCTAssertTrue(receivedRoot.flatMap { $0 } === rootViewController)
    }

    func testBanner_nilAdUnitIdAndRootViewController_arePassedThroughAsNil() {
        var receivedAdUnitId: String?? = .some("sentinel")
        var receivedRoot: UIViewController?? = .some(UIViewController())

        registry.registerBannerSource(for: TestSdk.yandex) { adUnitId, _, root in
            receivedAdUnitId = .some(adUnitId)
            receivedRoot = .some(root)
            return AnyVeonAdSourceLoading(MockAdSource<UIView>())
        }

        _ = registry.makeBannerSource(
            for: TestSdk.yandex,
            adUnitId: nil,
            adSize: CGSize(width: 300, height: 250),
            rootViewController: nil
        )

        XCTAssertNil(receivedAdUnitId ?? nil)
        XCTAssertNil(receivedRoot ?? nil)
    }

    func testBanner_reRegistering_replacesThePreviousFactory() {
        let first = MockAdSource<UIView>()
        let second = MockAdSource<UIView>()
        registry.registerBannerSource(for: TestSdk.gam) { _, _, _ in AnyVeonAdSourceLoading(first) }
        registry.registerBannerSource(for: TestSdk.gam) { _, _, _ in AnyVeonAdSourceLoading(second) }

        let source = registry.makeBannerSource(
            for: TestSdk.gam, adUnitId: "id", adSize: CGSize(width: 320, height: 50), rootViewController: nil
        )

        XCTAssertTrue(source?.underlying === second)
    }

    func testBanner_everyMakeCallCreatesAFreshSource() {
        var created = 0
        registry.registerBannerSource(for: TestSdk.yandex) { _, _, _ in
            created += 1
            return AnyVeonAdSourceLoading(MockAdSource<UIView>())
        }

        let a = registry.makeBannerSource(
            for: TestSdk.yandex, adUnitId: "id", adSize: CGSize(width: 320, height: 50), rootViewController: nil
        )
        let b = registry.makeBannerSource(
            for: TestSdk.yandex, adUnitId: "id", adSize: CGSize(width: 320, height: 50), rootViewController: nil
        )

        XCTAssertEqual(created, 2)
        XCTAssertNotNil(a)
        XCTAssertNotNil(b)
        XCTAssertFalse(a === b, "a source owns one in-flight request, so it must never be shared between races")
    }

    // MARK: - Interstitial

    func testInterstitial_registeredFactoryReceivesAdUnitIdAndIsUsed() {
        let mock = MockAdSource<VeonLoadedInterstitial>()
        var receivedAdUnitId: String??

        registry.registerInterstitialSource(for: TestSdk.gam) { adUnitId in
            receivedAdUnitId = .some(adUnitId)
            return AnyVeonAdSourceLoading(mock)
        }

        let source = registry.makeInterstitialSource(for: TestSdk.gam, adUnitId: "/1234/interstitial")

        XCTAssertNotNil(source)
        XCTAssertTrue(source?.underlying === mock)
        XCTAssertEqual(receivedAdUnitId, .some("/1234/interstitial"))
    }

    func testInterstitial_reRegistering_replacesThePreviousFactory() {
        let first = MockAdSource<VeonLoadedInterstitial>()
        let second = MockAdSource<VeonLoadedInterstitial>()
        registry.registerInterstitialSource(for: TestSdk.yandex) { _ in AnyVeonAdSourceLoading(first) }
        registry.registerInterstitialSource(for: TestSdk.yandex) { _ in AnyVeonAdSourceLoading(second) }

        let source = registry.makeInterstitialSource(for: TestSdk.yandex, adUnitId: "id")

        XCTAssertTrue(source?.underlying === second)
    }

    // MARK: - Thread safety

    func testRegistration_fromManyThreads_isSafe() {
        let registry = self.registry
        DispatchQueue.concurrentPerform(iterations: 200) { _ in
            registry.registerBannerSource(for: TestSdk.gam) { _, _, _ in
                AnyVeonAdSourceLoading(MockAdSource<UIView>())
            }
            registry.registerInterstitialSource(for: TestSdk.gam) { _ in
                AnyVeonAdSourceLoading(MockAdSource<VeonLoadedInterstitial>())
            }
        }

        XCTAssertNotNil(registry.makeBannerSource(
            for: TestSdk.gam, adUnitId: "id", adSize: CGSize(width: 320, height: 50), rootViewController: nil
        ))
        XCTAssertNotNil(registry.makeInterstitialSource(for: TestSdk.gam, adUnitId: "id"))
    }
}
