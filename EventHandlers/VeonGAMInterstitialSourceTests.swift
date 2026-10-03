//
// VeonGAMInterstitialSourceTests.swift
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

/// Paths of `VeonGAMInterstitialSource` that never reach the Google Mobile Ads SDK.
@MainActor
final class VeonGAMInterstitialSourceTests: XCTestCase {

    func testSdkIsGam() {
        XCTAssertEqual(VeonGAMInterstitialSource(adUnitId: "/1/interstitial").sdk, .gam)
    }

    func testLoad_withNilOrEmptyAdUnitId_failsWithMissingAdUnitId() {
        for adUnitId in [nil, ""] as [String?] {
            let source = VeonGAMInterstitialSource(adUnitId: adUnitId)
            var errors: [Error?] = []
            var loaded = 0
            source.onFailed = { errors.append($0) }
            source.onLoaded = { _ in loaded += 1 }

            source.load()

            XCTAssertEqual(errors.count, 1, "adUnitId: \(String(describing: adUnitId))")
            XCTAssertEqual(errors.first.flatMap { $0 } as? VeonGAMSourceError, .missingAdUnitId)
            XCTAssertEqual(loaded, 0)
        }
    }

    func testDestroy_isIdempotent_andSafeBeforeLoad() {
        let source = VeonGAMInterstitialSource(adUnitId: "/1/interstitial")

        source.destroy()
        source.destroy()
    }

    func testShow_beforeAnythingIsLoaded_isANoOp() {
        let source = VeonGAMInterstitialSource(adUnitId: "/1/interstitial")
        let recorder = InterstitialEventRecorder()
        source.interstitialDelegateForwarder = recorder

        source.show(from: UIViewController())

        XCTAssertTrue(recorder.events.isEmpty)
    }
}
