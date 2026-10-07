//
// VeonYandexAdSourceProviderTests.swift
// PrebidMultiAdLoaderYandexTests
//
// Copyright © Veon AdTech.
//

import UIKit
import XCTest
@testable import VeonPrebidMultiAdLoaderYandex
@testable import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

/// `register()` must make `.yandex` available to both loaders with sources that offer the
/// capabilities the loaders rely on.
@MainActor
final class VeonYandexAdSourceProviderTests: XCTestCase {

    private let registry = VeonAdSourceRegistry.shared

    func testRegister_makesAYandexBannerSourceAvailable() {
        VeonYandexAdSourceProvider.register()

        let source = registry.makeBannerSource(
            for: .yandex, adUnitId: "demo-banner", adSize: CGSize(width: 320, height: 50), rootViewController: UIViewController()
        )

        XCTAssertNotNil(source)
        XCTAssertTrue(source?.underlying is VeonYandexBannerSource)
    }

    func testRegister_bannerSourceCanReceiveTheLoadersForwarder() {
        VeonYandexAdSourceProvider.register()

        let source = registry.makeBannerSource(
            for: .yandex, adUnitId: "demo-banner", adSize: CGSize(width: 320, height: 50), rootViewController: nil
        )

        let forwardable = source?.underlying as? VeonBannerSourceForwardable
        XCTAssertNotNil(forwardable)
        XCTAssertEqual(forwardable?.sdk, .yandex)
    }

    /// Regression: the factory used to drop `rootViewController`, leaving the presenting
    /// view controller permanently nil (click-through browser could not be shown).
    func testRegister_threadsTheRootViewControllerThroughToTheBannerSource() {
        VeonYandexAdSourceProvider.register()
        let root = UIViewController()

        let source = registry.makeBannerSource(
            for: .yandex, adUnitId: "demo-banner", adSize: CGSize(width: 320, height: 50), rootViewController: root
        )

        let banner = source?.underlying as? VeonYandexBannerSource
        XCTAssertTrue(banner?.viewControllerForPresentingModalView() === root)
    }

    func testRegister_makesAYandexInterstitialSourceAvailable() {
        VeonYandexAdSourceProvider.register()

        let source = registry.makeInterstitialSource(for: .yandex, adUnitId: "demo-interstitial")

        XCTAssertTrue(source?.underlying is VeonYandexInterstitialSource)
        XCTAssertNotNil(source?.underlying as? VeonInterstitialSourceForwardable)
        XCTAssertEqual((source?.underlying as? VeonLoadedInterstitial)?.sdk, .yandex)
    }

    func testRegister_everyCallOfTheFactoryCreatesAFreshSource() {
        VeonYandexAdSourceProvider.register()

        let first = registry.makeInterstitialSource(for: .yandex, adUnitId: "id")
        let second = registry.makeInterstitialSource(for: .yandex, adUnitId: "id")

        XCTAssertNotNil(first)
        XCTAssertFalse(first?.underlying === second?.underlying)
    }

    func testRegister_calledTwice_stillWorks() {
        VeonYandexAdSourceProvider.register()
        VeonYandexAdSourceProvider.register()

        XCTAssertNotNil(registry.makeInterstitialSource(for: .yandex, adUnitId: "id"))
        XCTAssertNotNil(registry.makeBannerSource(
            for: .yandex, adUnitId: "id", adSize: CGSize(width: 300, height: 250), rootViewController: nil
        ))
    }
}
