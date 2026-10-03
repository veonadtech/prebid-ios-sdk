//
// VeonGAMBannerSourceTests.swift
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

/// Paths of `VeonGAMBannerSource` that never reach the Google Mobile Ads SDK.
@MainActor
final class VeonGAMBannerSourceTests: XCTestCase {

    private func makeSource(adUnitId: String?) -> VeonGAMBannerSource {
        VeonGAMBannerSource(adUnitId: adUnitId, adSize: CGSize(width: 320, height: 50), rootViewController: nil)
    }

    func testSdkIsGam() {
        XCTAssertEqual(makeSource(adUnitId: "/1/banner").sdk, .gam)
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
            XCTAssertEqual(errors.first.flatMap { $0 } as? VeonGAMSourceError, .missingAdUnitId)
            XCTAssertEqual(loaded, 0)
        }
    }

    func testMissingAdUnitIdError_hasAReadableDescription() {
        let error: Error = VeonGAMSourceError.missingAdUnitId

        XCTAssertEqual(error.localizedDescription, "GAM ad unit id is missing.")
    }

    func testDestroy_clearsCallbacks_andIsIdempotent() {
        let source = makeSource(adUnitId: "/1/banner")
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
