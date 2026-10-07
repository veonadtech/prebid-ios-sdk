//
// VeonGAMAdSourceProviderTests.swift
// PrebidMultiAdLoaderGAMTests
//
// Copyright © Veon AdTech.
//

import UIKit
import XCTest
#if canImport(VeonPrebidMultiAdLoaderGAM)
@testable import VeonPrebidMultiAdLoaderGAM
@testable import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig
#else
@testable import PrebidMultiAdLoaderGAM
@testable import PrebidMultiAdLoader
import PrebidRemoteConfig
#endif

/// `register()` must make `.gam` available to both loaders with sources that offer the
/// capabilities the loaders rely on (event forwarding, being the loaded interstitial).
@MainActor
final class VeonGAMAdSourceProviderTests: XCTestCase {

    private let registry = VeonAdSourceRegistry.shared

    func testRegister_makesAGamBannerSourceAvailable() {
        VeonGAMAdSourceProvider.register()

        let source = registry.makeBannerSource(
            for: .gam, adUnitId: "/1/banner", adSize: CGSize(width: 320, height: 50), rootViewController: UIViewController()
        )

        XCTAssertNotNil(source)
        XCTAssertTrue(source?.underlying is VeonGAMBannerSource)
    }

    func testRegister_bannerSourceCanReceiveTheLoadersForwarder() {
        VeonGAMAdSourceProvider.register()

        let source = registry.makeBannerSource(
            for: .gam, adUnitId: "/1/banner", adSize: CGSize(width: 320, height: 50), rootViewController: nil
        )

        let forwardable = source?.underlying as? VeonBannerSourceForwardable
        XCTAssertNotNil(forwardable, "VeonMultiBannerAdLoader casts the source to VeonBannerSourceForwardable")
        XCTAssertEqual(forwardable?.sdk, .gam)
    }

    func testRegister_makesAGamInterstitialSourceAvailable() {
        VeonGAMAdSourceProvider.register()

        let source = registry.makeInterstitialSource(for: .gam, adUnitId: "/1/interstitial")

        XCTAssertTrue(source?.underlying is VeonGAMInterstitialSource)
        XCTAssertNotNil(source?.underlying as? VeonInterstitialSourceForwardable)
        XCTAssertEqual((source?.underlying as? VeonLoadedInterstitial)?.sdk, .gam)
    }

    func testRegister_everyCallOfTheFactoryCreatesAFreshSource() {
        VeonGAMAdSourceProvider.register()

        let first = registry.makeInterstitialSource(for: .gam, adUnitId: "id")
        let second = registry.makeInterstitialSource(for: .gam, adUnitId: "id")

        XCTAssertNotNil(first)
        XCTAssertFalse(first?.underlying === second?.underlying)
    }

    func testRegister_calledTwice_stillWorks() {
        VeonGAMAdSourceProvider.register()
        VeonGAMAdSourceProvider.register()

        XCTAssertNotNil(registry.makeInterstitialSource(for: .gam, adUnitId: "id"))
        XCTAssertNotNil(registry.makeBannerSource(
            for: .gam, adUnitId: "id", adSize: CGSize(width: 300, height: 250), rootViewController: nil
        ))
    }
}
