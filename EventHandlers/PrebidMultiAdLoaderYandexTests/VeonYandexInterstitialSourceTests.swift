//
// VeonYandexInterstitialSourceTests.swift
// PrebidMultiAdLoaderYandexTests
//
// Copyright © Veon AdTech.
//

import UIKit
import XCTest
@testable import VeonPrebidMultiAdLoaderYandex
@testable import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

/// Paths of `VeonYandexInterstitialSource` that never reach the Yandex Mobile Ads SDK
/// (the SDK loader is a `lazy var` and is only created by a real `load()`).
///
/// Not covered: forwarding of the Yandex delegate callbacks — they take a Yandex `InterstitialAd`,
/// which cannot be created outside the SDK.
@MainActor
final class VeonYandexInterstitialSourceTests: XCTestCase {

    func testSdkIsYandex() {
        XCTAssertEqual(VeonYandexInterstitialSource(adUnitId: "demo-interstitial").sdk, .yandex)
    }

    func testLoad_withNilOrEmptyAdUnitId_failsWithMissingAdUnitId() {
        for adUnitId in [nil, ""] as [String?] {
            let source = VeonYandexInterstitialSource(adUnitId: adUnitId)
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

    func testDestroy_isIdempotent_andSafeBeforeLoad() {
        let source = VeonYandexInterstitialSource(adUnitId: "demo-interstitial")

        source.destroy()
        source.destroy()
    }

    func testShow_beforeAnythingIsLoaded_isANoOp() {
        let source = VeonYandexInterstitialSource(adUnitId: "demo-interstitial")
        let recorder = InterstitialEventRecorder()
        source.interstitialDelegateForwarder = recorder

        source.show(from: UIViewController())

        XCTAssertTrue(recorder.events.isEmpty)
    }
}
