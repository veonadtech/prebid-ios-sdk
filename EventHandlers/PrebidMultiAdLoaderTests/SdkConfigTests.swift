//
// SdkConfigTests.swift
// PrebidMultiAdLoaderTests
//
// Copyright © Veon AdTech.
//

import XCTest
@testable import VeonPrebidMultiAdLoader
@testable import VeonPrebidRemoteConfig

final class SdkConfigTests: XCTestCase {

    private func decode(_ json: String) throws -> SdkConfig {
        try JSONDecoder().decode(SdkConfig.self, from: Data(json.utf8))
    }

    // MARK: - SdkType

    func testSdkType_rawValuesMatchTheRemoteSchema() {
        XCTAssertEqual(SdkType.prebid.rawValue, "PREBID")
        XCTAssertEqual(SdkType.gam.rawValue, "GAM")
        XCTAssertEqual(SdkType.yandex.rawValue, "YANDEX")
    }

    func testSdkType_decodesFromRemoteStrings() throws {
        let decoded = try JSONDecoder().decode([SdkType].self, from: Data(#"["YANDEX","PREBID","GAM"]"#.utf8))

        XCTAssertEqual(decoded, [.yandex, .prebid, .gam])
    }

    func testSdkType_encodingRoundTrips() throws {
        let data = try JSONEncoder().encode(SdkType.allCases)
        let decoded = try JSONDecoder().decode([SdkType].self, from: data)

        XCTAssertEqual(decoded, SdkType.allCases)
    }

    // MARK: - Decoding

    func testDecode_documentedShape() throws {
        let config = try decode("""
        {
          "isActive": true,
          "sdkType": ["YANDEX", "GAM"],
          "level": "NONE",
          "sizes": ["320x50", "300x250"],
          "priority": ["PREBID", "YANDEX", "GAM"]
        }
        """)

        XCTAssertTrue(config.isActive)
        XCTAssertEqual(config.sdkType, [.yandex, .gam])
        XCTAssertEqual(config.sizes, ["320x50", "300x250"])
        XCTAssertEqual(config.priority, [.prebid, .yandex, .gam])
    }

    func testDecode_ignoresTheLoggingLevelAndUnknownKeys() throws {
        let config = try decode("""
        {"isActive": false, "sdkType": [], "sizes": [], "priority": ["GAM"], "level": "DEBUG", "somethingNew": 1}
        """)

        XCTAssertFalse(config.isActive)
        XCTAssertEqual(config.priority, [.gam])
    }

    func testDecode_isEquatable() throws {
        let json = RemoteConfigTestSupport.configJSON(priority: ["GAM", "PREBID"])

        XCTAssertEqual(try decode(json), try decode(json))
        XCTAssertNotEqual(try decode(json), try decode(RemoteConfigTestSupport.configJSON(priority: ["PREBID", "GAM"])))
    }

    func testDecode_missingRequiredKeyFails() {
        XCTAssertThrowsError(try decode(#"{"isActive": true, "sdkType": [], "sizes": []}"#), "priority is required")
        XCTAssertThrowsError(try decode(#"{"sdkType": [], "sizes": [], "priority": []}"#), "isActive is required")
    }

    /// Characterization test: ONE unknown SDK name makes the WHOLE config undecodable,
    /// so `SdkConfigStore` silently falls back to its default order for every client
    /// that doesn't know the new SDK yet. If that is not what you want, decode
    /// `[SdkType]` leniently (skip unknown values) and update this test.
    func testDecode_unknownSdkNameFailsTheWholeConfig() {
        XCTAssertThrowsError(try decode(RemoteConfigTestSupport.configJSON(priority: ["PREBID", "MAX", "GAM"])))
    }

    // MARK: - parsedSizes

    func testParsedSizes_parsesWidthAndHeight() throws {
        let config = try decode(RemoteConfigTestSupport.configJSON(priority: ["PREBID"], sizes: ["320x50", "300x250"]))

        XCTAssertEqual(config.parsedSizes, [CGSize(width: 320, height: 50), CGSize(width: 300, height: 250)])
    }

    func testParsedSizes_isCaseInsensitiveAndAcceptsDecimals() throws {
        let config = try decode(RemoteConfigTestSupport.configJSON(priority: ["PREBID"], sizes: ["728X90", "320.5x50.5"]))

        XCTAssertEqual(config.parsedSizes, [CGSize(width: 728, height: 90), CGSize(width: 320.5, height: 50.5)])
    }

    func testParsedSizes_skipsMalformedEntriesAndKeepsTheRest() throws {
        let config = try decode(RemoteConfigTestSupport.configJSON(
            priority: ["PREBID"],
            sizes: ["320x50", "abc", "320", "x50", "320x", "1x2x3", "axb", "", "300x250"]
        ))

        XCTAssertEqual(config.parsedSizes, [CGSize(width: 320, height: 50), CGSize(width: 300, height: 250)])
    }

    func testParsedSizes_emptyWhenNoSizes() throws {
        let config = try decode(RemoteConfigTestSupport.configJSON(priority: ["PREBID"], sizes: []))

        XCTAssertTrue(config.parsedSizes.isEmpty)
    }
}
