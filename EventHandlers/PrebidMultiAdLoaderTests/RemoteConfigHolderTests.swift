//
// RemoteConfigHolderTests.swift
// PrebidMultiAdLoaderTests
//
// Copyright © Veon AdTech.
//

import XCTest
#if canImport(VeonPrebidRemoteConfig)
@testable import VeonPrebidRemoteConfig
#else
@testable import PrebidRemoteConfig
#endif

/// `RemoteConfigHolder.shared` is a process-wide singleton whose `rawData` can only be
/// written by `load(from:)` and never cleared, so every test loads the body it needs first
/// and none relies on "nothing has been loaded yet".
final class RemoteConfigHolderTests: XCTestCase {

    private struct Probe: Decodable, Equatable {
        let name: String
        let value: Int
    }

    func testLoad_storesTheRawBodyAndReturnsItToTheCompletion() {
        let body = #"{"name":"a","value":1}"#

        let result = RemoteConfigTestSupport.load(json: body)

        guard case .success(let data)? = result else {
            return XCTFail("Expected success, got \(String(describing: result))")
        }
        XCTAssertEqual(String(decoding: data, as: UTF8.self), body)
        XCTAssertEqual(RemoteConfigHolder.shared.rawData, data)
    }

    func testDecode_returnsTheTypedValueForMatchingJSON() {
        RemoteConfigTestSupport.load(json: #"{"name":"a","value":1}"#)

        XCTAssertEqual(RemoteConfigHolder.shared.decode(Probe.self), Probe(name: "a", value: 1))
    }

    func testDecode_returnsNilWhenTheShapeDoesNotMatch() {
        RemoteConfigTestSupport.load(json: #"{"unrelated": true}"#)

        XCTAssertNil(RemoteConfigHolder.shared.decode(Probe.self))
    }

    func testDecode_returnsNilForNonJSONBody() {
        RemoteConfigTestSupport.load(json: "<html>502 Bad Gateway</html>")

        XCTAssertNil(RemoteConfigHolder.shared.decode(Probe.self))
    }

    func testDecode_sameRawDataCanBeReadByDifferentFeatures() {
        RemoteConfigTestSupport.load(json: #"{"name":"a","value":7,"extra":true}"#)

        struct OnlyValue: Decodable { let value: Int }
        struct OnlyName: Decodable { let name: String }

        XCTAssertEqual(RemoteConfigHolder.shared.decode(OnlyValue.self)?.value, 7)
        XCTAssertEqual(RemoteConfigHolder.shared.decode(OnlyName.self)?.name, "a")
    }

    func testLoad_secondSuccessfulLoadReplacesTheFirst() {
        RemoteConfigTestSupport.load(json: #"{"name":"first","value":1}"#)
        RemoteConfigTestSupport.load(json: #"{"name":"second","value":2}"#)

        XCTAssertEqual(RemoteConfigHolder.shared.decode(Probe.self), Probe(name: "second", value: 2))
    }

    func testLoad_emptyURLStringFailsWithBadURL() {
        var result: Result<Data, Error>?

        RemoteConfigHolder.shared.load(from: "") { result = $0 }

        guard case .failure(let error)? = result else {
            return XCTFail("Expected a synchronous failure, got \(String(describing: result))")
        }
        XCTAssertEqual((error as? URLError)?.code, .badURL)
    }

    func testLoad_failedFetchKeepsThePreviouslyLoadedConfig() {
        RemoteConfigTestSupport.load(json: #"{"name":"kept","value":3}"#)
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("does-not-exist-\(UUID().uuidString).json")
        let finished = expectation(description: "load finished")
        var result: Result<Data, Error>?

        RemoteConfigHolder.shared.load(from: missing.absoluteString) {
            result = $0
            finished.fulfill()
        }
        wait(for: [finished], timeout: 5)

        guard case .failure? = result else {
            return XCTFail("Expected failure, got \(String(describing: result))")
        }
        XCTAssertEqual(RemoteConfigHolder.shared.decode(Probe.self), Probe(name: "kept", value: 3))
    }
}
