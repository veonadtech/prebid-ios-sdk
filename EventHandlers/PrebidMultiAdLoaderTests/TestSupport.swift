//
// TestSupport.swift
// PrebidMultiAdLoaderTests
//
// Copyright © Veon AdTech.
//

import UIKit
import XCTest
@testable import VeonPrebidMultiAdLoader
@testable import VeonPrebidRemoteConfig

/// Non-isolated box used to collect objects created inside registry factories
/// (factories are plain, non-actor-isolated closures).
final class SourceRecorder<Source> {
    private(set) var created: [Source] = []

    @discardableResult
    func record(_ source: Source) -> Source {
        created.append(source)
        return source
    }

    var last: Source {
        guard let last = created.last else { fatalError("No source has been created yet") }
        return last
    }
}

enum RemoteConfigTestSupport {

    /// Builds a remote-config JSON body in the documented shape.
    static func configJSON(
        priority: [String],
        isActive: Bool = true,
        sdkType: [String]? = nil,
        sizes: [String] = ["320x50", "300x250"]
    ) -> String {
        func array(_ items: [String]) -> String {
            "[" + items.map { "\"\($0)\"" }.joined(separator: ",") + "]"
        }
        return """
        {"isActive": \(isActive), "sdkType": \(array(sdkType ?? priority)), "level": "NONE", \
        "sizes": \(array(sizes)), "priority": \(array(priority))}
        """
    }

    /// `RemoteConfigHolder.rawData` is `private(set)` and has no reset, so the
    /// only way to put a config into the shared holder is its (internal)
    /// `load(from:)`. A `file://` URL goes through the exact same code path as
    /// the real `configURL`, without any network.
    ///
    /// Blocks until the holder has stored the body (or the load failed).
    @discardableResult
    static func load(
        json: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Result<Data, Error>? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("veon-config-\(UUID().uuidString).json")
        do {
            try json.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Could not write config fixture: \(error)", file: file, line: line)
            return nil
        }
        defer { try? FileManager.default.removeItem(at: url) }

        var result: Result<Data, Error>?
        let semaphore = DispatchSemaphore(value: 0)
        RemoteConfigHolder.shared.load(from: url.absoluteString) { loadResult in
            result = loadResult
            semaphore.signal()
        }
        if semaphore.wait(timeout: .now() + 5) == .timedOut {
            XCTFail("Timed out loading config fixture", file: file, line: line)
        }
        return result
    }

    static func loadConfig(
        priority: [String],
        isActive: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        load(json: configJSON(priority: priority, isActive: isActive), file: file, line: line)
    }
}
