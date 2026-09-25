//
//  SdkType.swift
//  VeonPrebidRemoteConfig
//
//  Copyright © Veon AdTech.
//

import Foundation

/// Identifies which ad SDK is competing in the priority-based ad race
/// (`VeonMultiBannerAdLoader` / `VeonMultiInterstitialAdLoader`, both in
/// `VeonPrebidMultiAdLoader`).
///
/// Raw values match the strings used in the remote priority config
/// (see `SdkConfig`), e.g. `"PREBID"`, `"GAM"`, `"YANDEX"`.
public enum SdkType: String, Codable, CaseIterable, Hashable {
    case prebid = "PREBID"
    case gam = "GAM"
    case yandex = "YANDEX"
}
