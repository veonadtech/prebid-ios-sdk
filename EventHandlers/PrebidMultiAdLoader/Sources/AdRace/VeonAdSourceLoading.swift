//
//  VeonAdSourceLoading.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//

/// A source that can be raced by `VeonAdRace`. One conforming type per
/// ad SDK (Prebid / GAM / Yandex) per ad format (banner / interstitial).
///
/// Public so that optional modules (`PrebidMultiAdLoaderGAM`,
/// `PrebidMultiAdLoaderYandex`) can conform to it and register their
/// sources with `VeonAdSourceRegistry`.
///
/// Conformers own exactly one in-flight ad request. `destroy()` must
/// be safe to call multiple times and after `load()` was never called.
public protocol VeonAdSourceLoading: AnyObject {
    associatedtype AdObject

    /// Called once per race attempt. Must eventually call back into the
    /// owning `VeonAdRace` via `onLoaded` / `onFailed`.
    func load()

    /// Tears down the underlying ad object. Called both for sources that
    /// lost the race and, later, when the caller tears down the whole
    /// loader.
    func destroy()

    var onLoaded: ((AdObject) -> Void)? { get set }
    var onFailed: ((Error?) -> Void)? { get set }
}
