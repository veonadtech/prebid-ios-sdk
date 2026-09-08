//
//  VeonMultiAdLoaderError.swift
//  PrebidMultiAdLoader (Core)
//
//  Copyright © Veon AdTech.
//

import Foundation

enum VeonMultiAdLoaderError: LocalizedError {
    case missingConfigId(sdk: VeonSdkType)

    var errorDescription: String? {
        switch self {
        case .missingConfigId(let sdk):
            return "\(sdk.rawValue) ad unit / config id is missing."
        }
    }
}
