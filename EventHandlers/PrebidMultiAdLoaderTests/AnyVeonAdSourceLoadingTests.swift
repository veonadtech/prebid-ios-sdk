//
// AnyVeonAdSourceLoadingTests.swift
// PrebidMultiAdLoaderTests
//
// Copyright © Veon AdTech.
//

import XCTest
@testable import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

/// The type-erasing wrapper must behave exactly like the source it wraps:
/// `VeonAdRace` only ever talks to the wrapper.
@MainActor
final class AnyVeonAdSourceLoadingTests: XCTestCase {

    private var mock: MockAdSource<String>!
    private var wrapper: AnyVeonAdSourceLoading<String>!

    override func setUp() {
        super.setUp()
        mock = MockAdSource<String>()
        wrapper = AnyVeonAdSourceLoading(mock)
    }

    override func tearDown() {
        wrapper = nil
        mock = nil
        super.tearDown()
    }

    func testLoad_isForwardedToUnderlyingSource() {
        wrapper.load()
        wrapper.load()

        XCTAssertEqual(mock.loadCount, 2)
    }

    func testDestroy_isForwardedToUnderlyingSource() {
        wrapper.destroy()

        XCTAssertEqual(mock.destroyCount, 1)
    }

    func testOnLoaded_assignedOnWrapper_isCalledWhenUnderlyingLoads() {
        var received: [String] = []
        wrapper.onLoaded = { received.append($0) }

        mock.simulateLoaded("ad")

        XCTAssertEqual(received, ["ad"])
    }

    func testOnFailed_assignedOnWrapper_isCalledWithTheSameError() {
        var received: [Error?] = []
        wrapper.onFailed = { received.append($0) }

        mock.simulateFailure(MockAdError(code: 42))

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first.flatMap { $0 } as? MockAdError, MockAdError(code: 42))
    }

    func testCallbacks_clearedOnWrapper_areClearedOnUnderlyingSource() {
        wrapper.onLoaded = { _ in }
        wrapper.onFailed = { _ in }
        XCTAssertNotNil(mock.onLoaded)
        XCTAssertNotNil(mock.onFailed)

        wrapper.onLoaded = nil
        wrapper.onFailed = nil

        XCTAssertNil(mock.onLoaded)
        XCTAssertNil(mock.onFailed)
    }

    func testCallbacks_reassigned_replacePreviousOnes() {
        var first = 0
        var second = 0
        wrapper.onLoaded = { _ in first += 1 }
        wrapper.onLoaded = { _ in second += 1 }

        mock.simulateLoaded("ad")

        XCTAssertEqual(first, 0)
        XCTAssertEqual(second, 1)
    }

    func testUnderlying_returnsTheWrappedSource() {
        XCTAssertTrue(wrapper.underlying === mock)
    }

    func testUnderlying_allowsCastingToCapabilityProtocols() {
        // Core relies on this to reach e.g. `VeonBannerSourceForwardable`
        // without knowing the concrete SDK-specific type.
        XCTAssertNotNil(wrapper.underlying as? MockAdSource<String>)
        XCTAssertNil(wrapper.underlying as? VeonBannerSourceForwardable)
    }
}
