//
// VeonPrebidSourcesTests.swift
// PrebidMultiAdLoaderTests
//
// Copyright © Veon AdTech.
//

import UIKit
import XCTest
@testable import VeonPrebidMultiAdLoader
@testable import VeonPrebidRemoteConfig

/// The built-in Prebid sources, exercised only on the paths that never touch the Prebid SDK
/// (missing config id, destroy before load, nothing loaded yet).
@MainActor
final class VeonPrebidSourcesTests: XCTestCase {

    private func assertMissingConfigId(
        _ error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let error = error as? VeonMultiAdLoaderError,
              case .missingConfigId(let sdk) = error else {
            return XCTFail("Expected VeonMultiAdLoaderError.missingConfigId, got \(String(describing: error))", file: file, line: line)
        }
        XCTAssertEqual(sdk, .prebid, file: file, line: line)
    }

    // MARK: - Banner

    private func makeBanner(configId: String?) -> VeonPrebidBannerSource {
        VeonPrebidBannerSource(configId: configId, adSize: CGSize(width: 320, height: 50), refreshInterval: nil)
    }

    func testBanner_sdkIsPrebid() {
        XCTAssertEqual(makeBanner(configId: "id").sdk, .prebid)
    }

    func testBanner_load_withNilOrEmptyConfigId_failsWithMissingConfigId() {
        for configId in [nil, ""] as [String?] {
            let source = makeBanner(configId: configId)
            var errors: [Error?] = []
            var loaded = 0
            source.onFailed = { errors.append($0) }
            source.onLoaded = { _ in loaded += 1 }

            source.load()

            XCTAssertEqual(errors.count, 1, "configId: \(String(describing: configId))")
            assertMissingConfigId(errors.first.flatMap { $0 })
            XCTAssertEqual(loaded, 0)
        }
    }

    func testBanner_destroy_clearsCallbacks_andIsIdempotent() {
        let source = makeBanner(configId: "id")
        source.onLoaded = { _ in }
        source.onFailed = { _ in }

        source.destroy()
        source.destroy()

        XCTAssertNil(source.onLoaded)
        XCTAssertNil(source.onFailed)
    }

    func testBanner_presentationController_isThePresentingViewController() {
        let source = makeBanner(configId: "id")
        XCTAssertNil(source.bannerViewPresentationController())

        var presenter: UIViewController? = UIViewController()
        source.presentingViewController = presenter
        XCTAssertTrue(source.bannerViewPresentationController() === presenter)

        presenter = nil
        XCTAssertNil(source.bannerViewPresentationController(), "the presenter must be held weakly")
    }

    // MARK: - Interstitial

    func testInterstitial_sdkIsPrebid() {
        XCTAssertEqual(VeonPrebidInterstitialSource(configId: "id").sdk, .prebid)
    }

    func testInterstitial_load_withNilOrEmptyConfigId_failsWithMissingConfigId() {
        for configId in [nil, ""] as [String?] {
            let source = VeonPrebidInterstitialSource(configId: configId)
            var errors: [Error?] = []
            source.onFailed = { errors.append($0) }

            source.load()

            XCTAssertEqual(errors.count, 1, "configId: \(String(describing: configId))")
            assertMissingConfigId(errors.first.flatMap { $0 })
        }
    }

    func testInterstitial_destroyAndShowBeforeLoad_areSafeNoOps() {
        let source = VeonPrebidInterstitialSource(configId: "id")

        source.destroy()
        source.destroy()
        source.show(from: UIViewController())
    }
}
