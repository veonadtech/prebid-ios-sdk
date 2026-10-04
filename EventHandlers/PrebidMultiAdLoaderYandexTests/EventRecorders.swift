//
// EventRecorders.swift
//
// Copyright © Veon AdTech.
//

import Foundation
@testable import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

/// Stands in for the loader's private event forwarder and records what a banner source forwards.
final class BannerEventRecorder: VeonBannerEventForwarding {

    enum Event: Equatable {
        case impression(SdkType)
        case click(SdkType)
        case willLeaveApplication(SdkType)
        case willPresentScreen(SdkType)
        case willDismissScreen(SdkType)
        case didDismissScreen(SdkType)
    }

    private(set) var events: [Event] = []

    func bannerSourceDidRecordImpression(_ sdk: SdkType) { events.append(.impression(sdk)) }
    func bannerSourceDidRecordClick(_ sdk: SdkType) { events.append(.click(sdk)) }
    func bannerSourceWillLeaveApplication(_ sdk: SdkType) { events.append(.willLeaveApplication(sdk)) }
    func bannerSourceWillPresentScreen(_ sdk: SdkType) { events.append(.willPresentScreen(sdk)) }
    func bannerSourceWillDismissScreen(_ sdk: SdkType) { events.append(.willDismissScreen(sdk)) }
    func bannerSourceDidDismissScreen(_ sdk: SdkType) { events.append(.didDismissScreen(sdk)) }
}

/// Same for interstitial sources. Remembers the object the source passed as "itself".
final class InterstitialEventRecorder: VeonInterstitialEventForwarding {

    enum Event: Equatable {
        case willPresent(SdkType)
        case didDismiss(SdkType)
        case didClick(SdkType)
        case didFailToShow(SdkType)
        case didTrackImpression(SdkType)
    }

    private(set) var events: [Event] = []
    private(set) var lastSource: VeonLoadedInterstitial?
    private(set) var lastShowError: Error?

    func interstitialSourceWillPresent(_ source: VeonLoadedInterstitial) {
        lastSource = source
        events.append(.willPresent(source.sdk))
    }

    func interstitialSourceDidDismiss(_ source: VeonLoadedInterstitial) {
        lastSource = source
        events.append(.didDismiss(source.sdk))
    }

    func interstitialSourceDidClick(_ source: VeonLoadedInterstitial) {
        lastSource = source
        events.append(.didClick(source.sdk))
    }

    func interstitialSourceDidFailToShow(_ source: VeonLoadedInterstitial, error: Error?) {
        lastSource = source
        lastShowError = error
        events.append(.didFailToShow(source.sdk))
    }

    func interstitialSourceDidTrackImpression(_ source: VeonLoadedInterstitial) {
        lastSource = source
        events.append(.didTrackImpression(source.sdk))
    }
}
