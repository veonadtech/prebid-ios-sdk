//
// VeonYandexBannerSourceTests.swift
// PrebidMultiAdLoaderYandexTests
//
// Copyright © Veon AdTech.
//

import UIKit
import XCTest
@testable import VeonPrebidMultiAdLoaderYandex
@testable import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

/// Paths of `VeonYandexBannerSource` that never reach the Yandex Mobile Ads SDK.
@MainActor
final class VeonYandexBannerSourceTests: XCTestCase {

    private func makeSource(adUnitId: String?, root: UIViewController? = nil) -> VeonYandexBannerSource {
        VeonYandexBannerSource(adUnitId: adUnitId, adSize: CGSize(width: 320, height: 50), rootViewController: root)
    }

    func testSdkIsYandex() {
        XCTAssertEqual(makeSource(adUnitId: "demo-banner").sdk, .yandex)
    }

    func testLoad_withNilOrEmptyAdUnitId_failsWithMissingAdUnitId() {
        for adUnitId in [nil, ""] as [String?] {
            let source = makeSource(adUnitId: adUnitId)
            var errors: [Error?] = []
            var loaded = 0
            source.onFailed = { errors.append($0) }
            source.onLoaded = { _ in loaded += 1 }

            source.load()

            XCTAssertEqual(errors.count, 1, "adUnitId: \(String(describing: adUnitId))")
            XCTAssertEqual(errors.first.flatMap { $0 } as? VeonYandexSourceError, .missingAdUnitId)
            XCTAssertEqual(loaded, 0)
        }
    }

    func testMissingAdUnitIdError_hasAReadableDescription() {
        let error: Error = VeonYandexSourceError.missingAdUnitId

        XCTAssertEqual(error.localizedDescription, "Yandex ad unit id is missing.")
    }

    func testPresentingViewController_isTheRootViewControllerPassedAtInit() {
        let root = UIViewController()

        XCTAssertTrue(makeSource(adUnitId: "id", root: root).viewControllerForPresentingModalView() === root)
        XCTAssertNil(makeSource(adUnitId: "id", root: nil).viewControllerForPresentingModalView())
    }

    func testPresentingViewController_isHeldWeakly() {
        var root: UIViewController? = UIViewController()
        let source = makeSource(adUnitId: "id", root: root)

        root = nil

        XCTAssertNil(source.viewControllerForPresentingModalView())
    }

    func testDestroy_clearsCallbacks_andIsIdempotent() {
        let source = makeSource(adUnitId: "demo-banner")
        source.onLoaded = { _ in }
        source.onFailed = { _ in }

        source.destroy()
        source.destroy()

        XCTAssertNil(source.onLoaded)
        XCTAssertNil(source.onFailed)
    }

    func testDestroy_beforeLoadIsSafe() {
        makeSource(adUnitId: nil).destroy()
    }
}
