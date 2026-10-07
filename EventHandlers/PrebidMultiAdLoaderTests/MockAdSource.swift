//
// MockAdSource.swift
// PrebidMultiAdLoaderTests
//
// Copyright © Veon AdTech.
//

import XCTest
@testable import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

/// Short aliases for the `SdkType` cases used across the tests.
enum TestSdk {
    static let prebid = SdkType.prebid
    static let gam = SdkType.gam
    static let yandex = SdkType.yandex
}

/// Controllable `VeonAdSourceLoading` used to drive `VeonAdRace` deterministically.
///
/// Nothing happens on `load()` except counting the call; the test decides when
/// (and whether) the source reports success or failure via `simulateLoaded` /
/// `simulateFailure`.
final class MockAdSource<AdObject>: VeonAdSourceLoading {

    var onLoaded: ((AdObject) -> Void)?
    var onFailed: ((Error?) -> Void)?

    private(set) var loadCount = 0
    private(set) var destroyCount = 0

    func load() {
        loadCount += 1
    }

    func destroy() {
        destroyCount += 1
    }

    func simulateLoaded(_ adObject: AdObject) {
        onLoaded?(adObject)
    }

    func simulateFailure(_ error: Error? = nil) {
        onFailed?(error)
    }
}

/// Error used to check that failures are passed through untouched.
struct MockAdError: Error, Equatable {
    let code: Int
}
