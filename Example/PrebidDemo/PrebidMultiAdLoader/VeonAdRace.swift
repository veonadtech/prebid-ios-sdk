//
//  VeonAdRace.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//

import Foundation

/// State of a single SDK source within a race, mirroring the
/// `MultiBannerLoaderLegacyGam.SdkState` enum from the Android SDK.
enum VeonSdkRaceState<AdObject> {
    case notStarted
    case loading
    case loaded(AdObject)
    case failed(Error?)
}

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

/// Type-erased wrapper so `VeonAdRace` can hold a heterogeneous
/// `[VeonSdkType: AnyVeonAdSourceLoading<AdObject>]` dictionary.
///
/// Public: optional modules wrap their own `VeonAdSourceLoading`
/// conformers in this before handing them to `VeonAdSourceRegistry`.
public final class AnyVeonAdSourceLoading<AdObject>: VeonAdSourceLoading {

    private let _load: () -> Void
    private let _destroy: () -> Void
    private let _setOnLoaded: (((AdObject) -> Void)?) -> Void
    private let _setOnFailed: (((Error?) -> Void)?) -> Void

    public var onLoaded: ((AdObject) -> Void)? {
        didSet { _setOnLoaded(onLoaded) }
    }
    public var onFailed: ((Error?) -> Void)? {
        didSet { _setOnFailed(onFailed) }
    }

    public init<Source: VeonAdSourceLoading>(_ source: Source) where Source.AdObject == AdObject {
        _load = { source.load() }
        _destroy = { source.destroy() }
        _setOnLoaded = { source.onLoaded = $0 }
        _setOnFailed = { source.onFailed = $0 }
    }

    public func load() { _load() }
    public func destroy() { _destroy() }
}

/// Priority-ordered race between multiple ad SDK sources for a single
/// ad slot. First source (by priority) to report success wins; the
/// rest are destroyed. Mirrors `MultiBannerLoaderLegacyGam`'s
/// `trySelectAd` / `handleAdLoaded` / `handleAdFailed` logic, generalized
/// over the ad object type so both banner (`UIView`) and interstitial
/// (an opaque "ready to show" handle) can reuse it.
///
/// All calls into and out of `VeonAdRace` are expected to happen on the
/// main thread — ad SDK callbacks already land there, and this class
/// does not add its own synchronization.
final class VeonAdRace<AdObject> {

    private(set) var priorityOrder: [VeonSdkType]
    private var states: [VeonSdkType: VeonSdkRaceState<AdObject>] = [:]
    private let sources: [VeonSdkType: AnyVeonAdSourceLoading<AdObject>]
    private var selectedSDK: VeonSdkType?

    /// Fired once, when the first source in priority order finishes loading.
    var onLoaded: ((AdObject, VeonSdkType) -> Void)?

    /// Fired for every source that fails, in the order failures happen
    /// (not necessarily priority order).
    var onSourceFailed: ((VeonSdkType, Error?) -> Void)?

    init(priorityOrder: [VeonSdkType], sources: [VeonSdkType: AnyVeonAdSourceLoading<AdObject>]) {
        self.priorityOrder = priorityOrder.filter { sources[$0] != nil }
        self.sources = sources
    }

    func start() {
        destroy(resetState: false)
        selectedSDK = nil

        for sdk in priorityOrder {
            states[sdk] = .loading
        }

        for sdk in priorityOrder {
            guard let source = sources[sdk] else { continue }
            source.onLoaded = { [weak self] adObject in
                self?.handleLoaded(sdk: sdk, adObject: adObject)
            }
            source.onFailed = { [weak self] error in
                self?.handleFailed(sdk: sdk, error: error)
            }
            source.load()
        }
    }

    func destroy() {
        destroy(resetState: true)
    }

    private func destroy(resetState: Bool) {
        for source in sources.values {
            source.destroy()
        }
        if resetState {
            states.removeAll()
            selectedSDK = nil
        }
    }

    private func handleLoaded(sdk: VeonSdkType, adObject: AdObject) {
        states[sdk] = .loaded(adObject)
        trySelect()
    }

    private func handleFailed(sdk: VeonSdkType, error: Error?) {
        states[sdk] = .failed(error)
        priorityOrder.removeAll { $0 == sdk }
        onSourceFailed?(sdk, error)
        trySelect()
    }

    private func trySelect() {
        guard selectedSDK == nil, let firstSdk = priorityOrder.first else { return }

        guard case .loaded(let adObject) = states[firstSdk] else { return }

        selectedSDK = firstSdk
        for (sdk, source) in sources where sdk != firstSdk {
            source.destroy()
        }
        onLoaded?(adObject, firstSdk)
    }
}
