//
// VeonYandexBannerSourceForwardingTests.swift
// PrebidMultiAdLoaderYandexTests
//
// Copyright © Veon AdTech.
//
// Calls the Yandex delegate methods directly with a real (never loaded) `BannerAdView`.
// If `BannerAdView(adSize:)` / `BannerAdSize.fixed(width:height:)` differ in your SDK version,
// adjust `makeView()` — or delete this file, nothing else depends on it.
//

import YandexMobileAds
import UIKit
import XCTest
@testable import VeonPrebidMultiAdLoaderYandex
@testable import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

@MainActor
final class VeonYandexBannerSourceForwardingTests: XCTestCase {

    private var source: VeonYandexBannerSource!
    private var recorder: BannerEventRecorder!

    override func setUp() {
        super.setUp()
        source = VeonYandexBannerSource(adUnitId: "demo-banner", adSize: CGSize(width: 320, height: 50), rootViewController: nil)
        recorder = BannerEventRecorder()
        source.bannerDelegateForwarder = recorder
    }

    override func tearDown() {
        source = nil
        recorder = nil
        super.tearDown()
    }

    private func makeView() -> BannerAdView {
        BannerAdView(adSize: BannerAdSize.fixed(width: 320, height: 50))
    }

    func testDidLoad_passesTheViewToOnLoaded() {
        let view = makeView()
        var received: UIView?
        source.onLoaded = { received = $0 }

        source.bannerAdViewDidLoad(view)

        XCTAssertTrue(received === view)
    }

    func testDidFailLoading_passesTheErrorToOnFailed() {
        let error = NSError(domain: "yandex", code: 4)
        var received: Error??
        source.onFailed = { received = .some($0) }

        source.bannerAdViewDidFailLoading(makeView(), error: error)

        XCTAssertEqual((received ?? nil) as NSError?, error)
    }

    func testEngagementCallbacks_areForwardedWithTheYandexSdk() {
        let view = makeView()

        source.bannerAdView(view, didTrackImpression: nil)
        source.bannerAdViewDidClick(view)
        source.bannerAdViewDidClose(view)

        XCTAssertEqual(recorder.events, [.impression(.yandex), .click(.yandex), .didDismissScreen(.yandex)])
    }

    func testCallbacks_withoutAForwarder_doNothing() {
        source.bannerDelegateForwarder = nil

        source.bannerAdViewDidClick(makeView())

        XCTAssertTrue(recorder.events.isEmpty)
    }
}
