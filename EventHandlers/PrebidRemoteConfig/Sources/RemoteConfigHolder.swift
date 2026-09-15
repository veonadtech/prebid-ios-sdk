//
//  VeonRemoteConfig.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//

import Foundation

/// Thread-safe holder for the raw JSON fetched from `configURL` during
/// `Prebid.initializeSDK(serverURL:configURL:...)` (see
/// `Prebid+MultiAdLoaderInit.swift`).
///
/// Deliberately untyped: more than one feature keys off the same
/// `configURL` — this ad-loader module today (via `VeonSdkConfigHolder`),
/// a future logging module later (reading the `level` field this module
/// ignores). Each decodes only the slice it cares about via `decode(_:)`.
/// Nothing in this type is specific to ad mediation.
///
/// - Note: If a second feature module starts depending on this type,
///   consider extracting this file into its own small pod so a logging
///   module doesn't have to pull in GAM/Yandex as a transitive
///   dependency just to read `configURL`.
public final class RemoteConfigHolder {

    public static let shared = RemoteConfigHolder()

    private let lock = NSLock()
    private var _rawData: Data?

    private init() {}

    public var rawData: Data? {
        get { lock.lock(); defer { lock.unlock() }; return _rawData }
        set { lock.lock(); defer { lock.unlock() }; _rawData = newValue }
    }

    /// Decodes the current raw config as `T`, or `nil` if nothing has
    /// loaded yet, the load failed, or `T` doesn't match the JSON shape.
    public func decode<T: Decodable>(_ type: T.Type) -> T? {
        guard let rawData else { return nil }
        return try? JSONDecoder().decode(T.self, from: rawData)
    }

    /// Fetches `urlString` and stores the raw response body on success.
    /// Called once, from `Prebid.initializeSDK(serverURL:configURL:...)`;
    /// feature modules should read via `decode(_:)`, not call this directly.
    func load(from urlString: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(URLError(.zeroByteResource)))
                return
            }
            self?.rawData = data
            completion(.success(data))
        }
        task.resume()
    }
}
