//
//  VeonMultiAdLoaderError.swift
//  PrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//

import Foundation
import VeonPrebidRemoteConfig

enum VeonMultiAdLoaderError: LocalizedError {
    case missingConfigId(sdk: SdkType)

    var errorDescription: String? {
        switch self {
        case .missingConfigId(let sdk):
            return "\(sdk.rawValue) ad unit / config id is missing."
        }
    }
}
