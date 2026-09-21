//
//  AnyVeonAdSourceLoading.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//

/// Type-erased wrapper so `VeonAdRace` can hold a heterogeneous
/// `[SdkType: AnyVeonAdSourceLoading<AdObject>]` dictionary.
///
/// Public: optional modules wrap their own `VeonAdSourceLoading`
/// conformers in this before handing them to `VeonAdSourceRegistry`.
public final class AnyVeonAdSourceLoading<AdObject>: VeonAdSourceLoading {
    
    private let _load: () -> Void
    private let _destroy: () -> Void
    private let _setOnLoaded: (((AdObject) -> Void)?) -> Void
    private let _setOnFailed: (((Error?) -> Void)?) -> Void
    
    /// The wrapped concrete source, exposed so callers can cast to
    /// optional capability protocols the wrapped source may conform to
    /// (e.g. `VeonBannerSourceForwardable`, `VeonInterstitialSourceForwardable`)
    /// without Core needing to know the concrete SDK-specific type.
    public let underlying: AnyObject
    
    public var onLoaded: ((AdObject) -> Void)? {
        didSet { _setOnLoaded(onLoaded) }
    }
    public var onFailed: ((Error?) -> Void)? {
        didSet { _setOnFailed(onFailed) }
    }
    
    public init<Source: VeonAdSourceLoading>(_ source: Source) where Source.AdObject == AdObject {
        underlying = source
        _load = { source.load() }
        _destroy = { source.destroy() }
        _setOnLoaded = { source.onLoaded = $0 }
        _setOnFailed = { source.onFailed = $0 }
    }
    
    public func load() { _load() }
    public func destroy() { _destroy() }
}
