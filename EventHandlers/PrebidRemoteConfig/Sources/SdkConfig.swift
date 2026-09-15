//
//  VeonMultiAdLoaderConfig.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//

import CoreGraphics
import Foundation
//import VeonPrebidRemoteConfig

/// Remote configuration describing which SDKs participate in the ad race
/// and in what priority order.
///
/// Expected JSON shape:
/// ```json
/// {
///   "isActive": true,
///   "sdkType": ["YANDEX", "GAM"],
///   "level": "NONE",
///   "sizes": ["320x50", "300x250"],
///   "priority": ["PREBID", "YANDEX", "GAM"]
/// }
/// ```
///
/// - Note: `level` is intentionally **not** modeled here. It relates to a
///   logging configuration that is out of scope for this module right now.
///   Only `priority` (and `isActive`) drive the actual race logic.
public struct SdkConfig: Decodable, Equatable {

    /// Master switch. When `false`, `VeonSdkConfigHolder.priorityOrder`
    /// falls back to Prebid-only behavior.
    public let isActive: Bool

    /// SDKs that are allowed to participate at all. Currently informational —
    /// `priority` is the list actually raced against, but this is kept
    /// around for parity with the remote schema and future filtering.
    public let sdkType: [SdkType]

    /// Raw size strings, e.g. `"320x50"`. Use `parsedSizes` to get `CGSize`.
    public let sizes: [String]

    /// The order in which SDKs are tried. First loaded ad in this order wins.
    public let priority: [SdkType]

    enum CodingKeys: String, CodingKey {
        case isActive, sdkType, sizes, priority
    }
}

extension SdkConfig {

    /// Parses `"WxH"` strings from `sizes` into `CGSize` values.
    /// Malformed entries are silently skipped.
    public var parsedSizes: [CGSize] {
        sizes.compactMap { entry in
            let parts = entry.lowercased().split(separator: "x")
            guard parts.count == 2,
                  let width = Double(parts[0]),
                  let height = Double(parts[1]) else {
                return nil
            }
            return CGSize(width: width, height: height)
        }
    }
}
