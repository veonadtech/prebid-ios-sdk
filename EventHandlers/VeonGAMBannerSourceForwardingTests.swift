//
// VeonGAMBannerSourceForwardingTests.swift
// PrebidMultiAdLoaderGAMTests
//
// Copyright © Veon AdTech.
//
// Calls the GAM delegate methods directly with a real (never loaded) GoogleMobileAds `BannerView`.
// If `BannerView(adSize:)` / `AdSizeBanner` differ in your GMA version, adjust `makeView()`.
//

import GoogleMobileAds
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

@MainActor
final class VeonGAMBannerSourceForwardingTests: XCTestCase {

    private var source: VeonGAMBannerSource!
    private var recorder: BannerEventRecorder!

    override func setUp() {
        super.setUp()
        source = VeonGAMBannerSource(adUnitId: "/1/banner", adSize: CGSize(width: 320, height: 50), rootViewController: nil)
        recorder = BannerEventRecorder()
        source.bannerDelegateForwarder = recorder
    }

    override func tearDown() {
        source = nil
        recorder = nil
        super.tearDown()
    }

    private func makeView() -> BannerView {
        BannerView(adSize: AdSizeBanner)
    }

    func testDidReceiveAd_passesTheViewToOnLoaded() {
        let view = makeView()
        var received: UIView?
        source.onLoaded = { received = $0 }

        source.bannerViewDidReceiveAd(view)

        XCTAssertTrue(received === view)
    }

    func testDidFailToReceiveAd_passesTheErrorToOnFailed() {
        let error = NSError(domain: "gma", code: 3)
        var received: Error??
        source.onFailed = { received = .some($0) }

        source.bannerView(makeView(), didFailToReceiveAdWithError: error)

        XCTAssertEqual((received ?? nil) as NSError?, error)
    }

    func testEngagementCallbacks_areForwardedWithTheGamSdk() {
        let view = makeView()

        source.bannerViewDidRecordImpression(view)
        source.bannerViewDidRecordClick(view)
        source.bannerViewWillPresentScreen(view)
        source.bannerViewWillDismissScreen(view)
        source.bannerViewDidDismissScreen(view)

        XCTAssertEqual(recorder.events, [
            .impression(.gam),
            .click(.gam),
            .willPresentScreen(.gam),
            .willDismissScreen(.gam),
            .didDismissScreen(.gam)
        ])
    }

    func testEngagementCallbacks_withoutAForwarder_doNothing() {
        source.bannerDelegateForwarder = nil

        source.bannerViewDidRecordClick(makeView())

        XCTAssertTrue(recorder.events.isEmpty)
    }
}
