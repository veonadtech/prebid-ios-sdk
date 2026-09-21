/*   Copyright © Veon AdTech.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit
import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig

fileprivate let storedImpMultiAdLoaderInterstitial = "_prebid-demo-display-interstitial-320-480"
fileprivate let gamAdUnitMultiAdLoaderInterstitial = "_/21775744923/example/interstitial"
fileprivate let yandexAdUnitMultiAdLoaderInterstitial = "demo-interstitial-yandex"

/// Same shape as `InAppDisplayInterstitialViewController` — loads on
/// screen push and shows immediately once a source wins the race.
class MultiAdLoaderDisplayInterstitialViewController: UIViewController {

    private var loader: VeonMultiInterstitialAdLoader!

    override func loadView() {
        super.loadView()
        
        createAd()
    }

    deinit {
        loader?.destroy()
    }

    func createAd() {
        // 1. Create the race loader
        loader = VeonMultiInterstitialAdLoader(
            configId: storedImpMultiAdLoaderInterstitial,
            gamAdUnitId: gamAdUnitMultiAdLoaderInterstitial,
            yandexAdUnitId: yandexAdUnitMultiAdLoaderInterstitial
        )
        loader.delegate = self

        // 2. Load
        loader.loadAd()
    }
}

extension MultiAdLoaderDisplayInterstitialViewController: VeonMultiInterstitialAdLoaderDelegate {

    // MARK: - Load

    // All three SDKs (Prebid / GAM / Yandex) — fires from VeonAdRace.onLoaded
    // for whichever source wins the priority race.
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didLoadFrom sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader interstitial won by \(sdk.rawValue)")
        loader.show(from: self)
    }

    // All three SDKs — fires for any source that fails during the race.
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didFailToLoad sdk: SdkType, error: Error?) {
        PrebidDemoLogger.shared.error("Multi Ad Loader interstitial did fail for \(sdk.rawValue) with error: \(String(describing: error))")
    }

    // Not tied to a specific SDK — fires once every registered source has failed.
    func interstitialLoaderDidFailAll(_ loader: VeonMultiInterstitialAdLoader) {
        PrebidDemoLogger.shared.error("Multi Ad Loader interstitial: all sources failed")
    }

    // MARK: - Show

    // All three SDKs, but note a timing difference: GAM's
    // adWillPresentFullScreenContent and Prebid's interstitialWillPresentAd
    // are genuinely "about to present". Yandex maps this from
    // interstitialAdDidShow — i.e. Yandex fires this AFTER the ad is already
    // shown, not before. Don't rely on ordering relative to the actual
    // screen transition for sdk == .yandex.
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, willPresent sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader interstitial will present for \(sdk.rawValue)")
    }

    // All three SDKs.
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didDismiss sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader interstitial did dismiss for \(sdk.rawValue)")
    }

    // All three SDKs: Yandex (interstitialAdDidClick), GAM (adDidRecordClick),
    // Prebid (interstitialDidClickAd).
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didClick sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader interstitial did click for \(sdk.rawValue)")
    }

    // GAM and Yandex only. VeonPrebidInterstitialSource's InterstitialAdUnitDelegate
    // conformance never forwards a "did fail to show" event — this never fires
    // for sdk == .prebid, even though the underlying PrebidMobile SDK does
    // have such a delegate callback; it's simply not wired here.
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didFailToShow sdk: SdkType, error: Error?) {
        PrebidDemoLogger.shared.error("Multi Ad Loader interstitial did fail to show for \(sdk.rawValue) with error: \(String(describing: error))")
    }

    // MARK: - Impression

    // GAM and Yandex only. VeonPrebidInterstitialSource never forwards an
    // impression event at all — this never fires for sdk == .prebid.
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didTrackImpression sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader interstitial did track impression for \(sdk.rawValue)")
    }
}
