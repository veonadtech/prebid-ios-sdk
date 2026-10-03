//
// VeonMultiAdLoaderErrorTests.swift
// PrebidMultiAdLoaderTests
//
// Copyright © Veon AdTech.
//

import XCTest
#if canImport(VeonPrebidMultiAdLoader)
@testable import VeonPrebidMultiAdLoader
@testable import VeonPrebidRemoteConfig
#else
@testable import PrebidMultiAdLoader
@testable import PrebidRemoteConfig
#endif

final class VeonMultiAdLoaderErrorTests: XCTestCase {

    func testMissingConfigId_descriptionNamesThePrebidSdk() {
        let error = VeonMultiAdLoaderError.missingConfigId(sdk: .prebid)

        XCTAssertEqual(error.errorDescription, "PREBID ad unit / config id is missing.")
    }

    func testMissingConfigId_descriptionStartsWithTheRawValueOfEverySdk() {
        for sdk in SdkType.allCases {
            let description = VeonMultiAdLoaderError.missingConfigId(sdk: sdk).errorDescription

            XCTAssertNotNil(description)
            XCTAssertTrue(description?.hasPrefix(sdk.rawValue) ?? false, "\(sdk) → \(String(describing: description))")
        }
    }

    func testLocalizedDescription_matchesErrorDescription() {
        let error: Error = VeonMultiAdLoaderError.missingConfigId(sdk: .gam)

        XCTAssertEqual(error.localizedDescription, "GAM ad unit / config id is missing.")
    }
}
