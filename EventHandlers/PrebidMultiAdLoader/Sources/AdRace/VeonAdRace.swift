//
//  VeonAdRace.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//

import VeonPrebidRemoteConfig

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
    
    private(set) var priorityOrder: [SdkType]
    private var states: [SdkType: VeonSdkRaceState<AdObject>] = [:]
    private let sources: [SdkType: AnyVeonAdSourceLoading<AdObject>]
    private var selectedSDK: SdkType?
    
    /// Fired once, when the first source in priority order finishes loading.
    var onLoaded: ((AdObject, SdkType) -> Void)?
    
    /// Fired for every source that fails, in the order failures happen
    /// (not necessarily priority order).
    var onSourceFailed: ((SdkType, Error?) -> Void)?
    
    init(priorityOrder: [SdkType], sources: [SdkType: AnyVeonAdSourceLoading<AdObject>]) {
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
    
    private func handleLoaded(sdk: SdkType, adObject: AdObject) {
        states[sdk] = .loaded(adObject)
        trySelect()
    }
    
    private func handleFailed(sdk: SdkType, error: Error?) {
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
