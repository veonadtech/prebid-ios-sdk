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

private let storedImpMultiAdLoaderBanner = "prebid-demo-banner-320-50"
private let gamAdUnitMultiAdLoaderBanner = "_/21775744923/example/fixed-size-banner"
private let yandexAdUnitMultiAdLoaderBanner = "_demo-banner-yandex"
private let refreshInterval: TimeInterval = 30


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
            refreshInterval: refreshInterval,
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

    // Fires for all three SDKs (Prebid / GAM / Yandex) — whichever wins the race.
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didLoad view: UIView, from sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader banner won by \(sdk.rawValue)")
        
        bannerView?.subviews.forEach { $0.removeFromSuperview() }
        bannerView?.addSubview(view)
    }

    // Fires for all three SDKs — any source that fails during the race, win or lose.
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didFailToLoad sdk: SdkType, error: Error?) {
        PrebidDemoLogger.shared.error("Multi Ad Loader banner did fail for \(sdk.rawValue) with error: \(String(describing: error))")
    }

    // Fires once all registered sources have failed. Not tied to a specific SDK.
    func bannerLoaderDidFailAll(_ loader: VeonMultiBannerAdLoader) {
        PrebidDemoLogger.shared.error("Multi Ad Loader banner: all sources failed")
    }

    // MARK: - Engagement events (winning source only)

    // All three SDKs: GAM (bannerViewDidRecordImpression), Yandex (didTrackImpression),
    // Prebid (bannerViewDidDisplay).
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordImpressionFrom sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader banner (\(sdk.rawValue)) recorded impression")
    }

    // GAM and Yandex only. Prebid's BannerViewDelegate has no click callback,
    // so this never fires for sdk == .prebid.
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordClickFrom sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader banner (\(sdk.rawValue)) recorded click")
    }
    
    // Yandex (adViewWillLeaveApplication) and Prebid (bannerViewWillLeaveApplication)
    // only. GAM's BannerViewDelegate has no equivalent event — a GAM click that
    // opens an external app currently produces no signal here at all beyond
    // didRecordClickFrom.
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willLeaveApplication sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader banner (\(sdk.rawValue)) will leave application")
    }

    // All three SDKs, but only when the click opens something in-app (modal /
    // embedded browser). If the click instead backgrounds the app, this is
    // skipped in favor of onWillLeaveApplication (not currently forwarded here).
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willPresentScreenFrom sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader banner (\(sdk.rawValue)) will present screen")
    }

    // GAM only, in case with in-app screen. Yandex's AdViewDelegate has no "will dismiss" event (only
    // willPresent/didDismiss), and Prebid's BannerViewDelegate has no
    // equivalent either — so this never fires for sdk == .yandex or .prebid.
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, willDismissScreenFrom sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader banner (\(sdk.rawValue)) will dismiss screen")
    }

    // All three SDKs, mirroring willPresentScreenFrom above — only fires if an
    // in-app screen was actually presented and then dismissed.
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didDismissScreenFrom sdk: SdkType) {
        PrebidDemoLogger.shared.info("Multi Ad Loader banner (\(sdk.rawValue)) did dismiss screen")
    }
}
