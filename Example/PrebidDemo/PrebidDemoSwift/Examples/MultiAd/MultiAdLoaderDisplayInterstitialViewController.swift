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
    
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didLoadFrom sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader interstitial won by \(sdk.rawValue)")
        loader.show(from: self)
    }
    
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didFailToLoad sdk: SdkType, error:  Error?) {
        PrebidDemoLogger.shared.error("Multi Ad Loader interstitial did fail for \(sdk.rawValue) with error: \(String(describing: error))")
    }

    func interstitialLoaderDidFailAll(_ loader: VeonMultiInterstitialAdLoader) {
        PrebidDemoLogger.shared.error("Multi Ad Loader interstitial: all sources failed")
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didFailToShow sdk: SdkType, error: Error?) {
        PrebidDemoLogger.shared.error("Multi Ad Loader interstitial did fail to show for \(sdk.rawValue) with error: \(String(describing: error))")
    }
}
