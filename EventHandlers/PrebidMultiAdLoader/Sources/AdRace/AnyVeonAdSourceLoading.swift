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

    /// `public var` (not `internal(set)`) because `VeonAdSourceLoading`
    /// requires `{ get set }` — Swift requires a public protocol's
    /// requirement to be satisfied by an equally-visible witness, so the
    /// setter can't be narrowed here.
    ///
    /// This is safe in practice even though the setter is technically
    /// public: an `AnyVeonAdSourceLoading` instance never reaches app
    /// code. It's only ever created inside this module or an optional
    /// GAM/Yandex module and immediately handed to `VeonAdRace` (which
    /// sets these callbacks once, in `start()`) or stored in
    /// `VeonAdSourceRegistry`'s `internal` factory maps. The integrator's
    /// only public surface is `VeonMultiBannerAdLoader` /
    /// `VeonMultiInterstitialAdLoader`, neither of which exposes this
    /// type or an instance of it.
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
