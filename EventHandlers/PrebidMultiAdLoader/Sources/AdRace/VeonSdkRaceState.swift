//
//  VeonSdkRaceState.swift
//  VeonPrebidMultiAdLoader
//
//  Copyright © Veon AdTech.
//

/// State of a single SDK source within a race, mirroring the
/// `MultiBannerLoaderLegacyGam.SdkState` enum from the Android SDK.
enum VeonSdkRaceState<AdObject> {
    case notStarted
    case loading
    case loaded(AdObject)
    case failed(Error?)
}
