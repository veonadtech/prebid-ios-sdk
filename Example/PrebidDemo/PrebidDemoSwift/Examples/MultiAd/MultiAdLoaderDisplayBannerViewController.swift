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

fileprivate let storedImpMultiAdLoaderBanner = "_prebid-demo-banner-320-50"
fileprivate let gamAdUnitMultiAdLoaderBanner = "/21775744923/example/fixed-size-banner"
fileprivate let yandexAdUnitMultiAdLoaderBanner = "demo-banner-yandex"

/// Same base class as the other banner demo screens (`GAMOriginalAPIDisplayBannerViewController`,
/// `InAppDisplayBannerViewController`, etc.) — reuses its `adSize` and
/// `bannerView` container.
class MultiAdLoaderDisplayBannerViewController: BannerBaseViewController {

    private var loader: VeonMultiBannerAdLoader!

    override func loadView() {
        super.loadView()
        
        createAd()
    }

    deinit {
        loader?.destroy()
    }

    func createAd() {
        // 1. Create the race loader — no need to construct Prebid/GAM/Yandex
        // ad units directly; each registered source builds and races its
        // own request internally.
        loader = VeonMultiBannerAdLoader(
            rootViewController: self,
            adSize: adSize,
            configId: storedImpMultiAdLoaderBanner,
            gamAdUnitId: gamAdUnitMultiAdLoaderBanner,
            yandexAdUnitId: yandexAdUnitMultiAdLoaderBanner
        )
        loader.delegate = self

        // 2. Load — whichever of Prebid/GAM/Yandex is registered and wins
        // by priority order shows up in didLoad below.
        loader.loadAd()
    }
}

extension MultiAdLoaderDisplayBannerViewController: VeonMultiBannerAdLoaderDelegate {

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didLoad view: UIView, from sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader banner won by \(sdk.rawValue)")
        
        bannerView?.subviews.forEach { $0.removeFromSuperview() }
        bannerView?.addSubview(view)
    }

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didFailToLoad sdk: SdkType, error: Error?) {
        PrebidDemoLogger.shared.error("Multi Ad Loader banner did fail for \(sdk.rawValue) with error: \(String(describing: error))")
    }

    func bannerLoaderDidFailAll(_ loader: VeonMultiBannerAdLoader) {
        PrebidDemoLogger.shared.error("Multi Ad Loader banner: all sources failed")
    }
}
