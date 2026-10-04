//
// VeonGAMInterstitialSourceForwardingTests.swift
// PrebidMultiAdLoaderGAMTests
//
// Copyright © Veon AdTech.
//
// Calls the `FullScreenContentDelegate` methods directly with a stub `FullScreenPresentingAd`.
// If your GoogleMobileAds version declares more requirements on that protocol, extend the stub
// (or delete this file — the rest of the GAM tests do not depend on it).
//

import GoogleMobileAds
import UIKit
import XCTest
@testable import VeonPrebidMultiAdLoader
@testable import VeonPrebidRemoteConfig

private final class StubFullScreenAd: NSObject, FullScreenPresentingAd {
    weak var fullScreenContentDelegate: (any FullScreenContentDelegate)?
}

@MainActor
final class VeonGAMInterstitialSourceForwardingTests: XCTestCase {

    private var source: VeonGAMInterstitialSource!
    private var recorder: InterstitialEventRecorder!
    private let ad = StubFullScreenAd()

    override func setUp() {
        super.setUp()
        source = VeonGAMInterstitialSource(adUnitId: "/1/interstitial")
        recorder = InterstitialEventRecorder()
        source.interstitialDelegateForwarder = recorder
    }

    override func tearDown() {
        source = nil
        recorder = nil
        super.tearDown()
    }

    func testFullScreenCallbacks_areForwardedWithTheGamSdk() {
        source.adWillPresentFullScreenContent(ad)
        source.adDidRecordImpression(ad)
        source.adDidRecordClick(ad)
        source.adDidDismissFullScreenContent(ad)

        XCTAssertEqual(recorder.events, [
            .willPresent(.gam),
            .didTrackImpression(.gam),
            .didClick(.gam),
            .didDismiss(.gam)
        ])
    }

    func testFailToPresent_isForwardedWithTheError() {
        let error = NSError(domain: "gma", code: 9)

        source.ad(ad, didFailToPresentFullScreenContentWithError: error)

        XCTAssertEqual(recorder.events, [.didFailToShow(.gam)])
        XCTAssertEqual(recorder.lastShowError as NSError?, error)
    }

    func testForwardedSource_isTheGamSourceItself() {
        source.adDidRecordClick(ad)

        XCTAssertTrue(recorder.lastSource === source, "the loader identifies the winner through the source it is handed")
    }

    func testCallbacks_withoutAForwarder_doNothing() {
        source.interstitialDelegateForwarder = nil

        source.adDidRecordClick(ad)

        XCTAssertTrue(recorder.events.isEmpty)
    }
}
