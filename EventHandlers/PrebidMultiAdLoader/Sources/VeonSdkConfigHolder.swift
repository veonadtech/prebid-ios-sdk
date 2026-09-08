//
//  VeonSdkConfigHolder.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//

import Foundation
import VeonPrebidRemoteConfig

/// Ad-mediation view onto the shared remote config.
///
/// Fetching and storage live in `VeonRemoteConfig` (module
/// `VeonPrebidRemoteConfig`), populated by
/// `Prebid.initializeSDK(serverURL:configURL:...)`. This type only
/// decodes the slice of that JSON this module cares about
/// (`VeonMultiAdLoaderConfig`) and derives the race's priority order —
/// it holds no state of its own.
public enum VeonSdkConfigHolder {

    /// The currently decoded ad-loader config, or `nil` if nothing has
    /// loaded yet, or the JSON doesn't match `VeonMultiAdLoaderConfig`'s
    /// shape.
    public static var config: VeonMultiAdLoaderConfig? {
        VeonRemoteConfig.shared.decode(VeonMultiAdLoaderConfig.self)
    }

    /// Priority order to race SDKs in.
    ///
    /// Falls back to Prebid-only (`[.prebid]`) if no config was loaded,
    /// the config is inactive, or `priority` is empty — so the race
    /// modules degrade to "just use Prebid" rather than doing nothing.
    public static var priorityOrder: [VeonSdkType] {
        guard let config, config.isActive, !config.priority.isEmpty else {
            return [.prebid]
        }
        return config.priority
    }

    public static var isActive: Bool {
        config?.isActive ?? false
    }
}
