//
//  Prebid+RemoteConfig.swift
//  VeonPrebidRemoteConfig
//
//  Copyright © Veon AdTech.
//

import Foundation
import PrebidMobile

/// Adds a `configURL` parameter to `Prebid.initializeSDK`, without touching
/// core (`VeonPrebidMobile`) at all — this is a plain Swift extension of
/// the public `Prebid` class, shipped from this separate module.
///
/// Any feature that keys off the same remote config (today: the ad-mediation
/// priority order in `VeonPrebidMultiAdLoader`; later: logging verbosity)
/// reads it back via `VeonRemoteConfig.shared.decode(_:)` — this file only
/// owns *fetching and storing* the raw JSON, not interpreting it.
public extension Prebid {

    /// Same as `Prebid.initializeSDK(serverURL:_:_:)`, plus an optional
    /// `configURL` that is fetched in the background and made available to
    /// any module reading `VeonRemoteConfig.shared`.
    ///
    /// The config fetch is fire-and-forget with respect to core
    /// initialization: a slow, missing, or malformed `configURL` never
    /// delays or fails `completion` for the core SDK init. Consumers
    /// (e.g. `VeonSdkConfigHolder.priorityOrder`) are expected to degrade
    /// gracefully when nothing has loaded yet.
    ///
    /// - Parameters:
    ///   - serverURL: The custom Prebid Server URL. Forwarded as-is.
    ///   - configURL: URL returning the shared remote config JSON
    ///     (ad priority today, log level later). Pass `nil` to skip.
    ///   - gadMobileAdsObject: Forwarded as-is to the core initializer.
    ///   - completion: Forwarded as-is — fires for core SDK init only,
    ///     independent of the `configURL` fetch.
    static func initializeSDK(
        serverURL: String,
        configURL: String?,
        gadMobileAdsObject: AnyObject? = nil,
        completion: PrebidInitializationCallback? = nil
    ) throws {
        if let configURL, !configURL.isEmpty {
            VeonRemoteConfig.shared.load(from: configURL) { _ in
                // Intentionally ignored here — a failed/garbled config
                // just leaves VeonRemoteConfig.shared.rawData nil, and
                // every consumer already has a defined fallback for that.
                // If you need to surface load failures (e.g. to logging
                // once that module exists), observe VeonRemoteConfig
                // directly rather than adding a completion param here —
                // that keeps this signature stable as more features
                // start depending on the same configURL.
            }
        }

        try Prebid.initializeSDK(serverURL: serverURL, gadMobileAdsObject, completion)
    }
}
