## Build scripts directory for Prebid Mobile

To build the Prebid Mobile frameworks (XCFrameworks for every module) run:

```
./buildPrebidMobile.sh
```

To test the Prebid Mobile framework run:

```
./testPrebidMobile.sh
```

To test the adapters / event handlers / multi-ad loader modules run:

```
./testPrebidMobileAdapters.sh
```

To run the demo app tests (integration by default, `-ui` for UI tests) run:

```
./testPrebidDemo.sh [-ui]
```

Other scripts:

| Script | Purpose |
| --- | --- |
| `buildPrebidSPM.sh` | Builds the `PrebidDemoSPM` demo app (checks the SPM integration, including Google Mobile Ads and Yandex Ads packages) |
| `publishSPM.sh <workdir> <version> <target_branch>` | Commits, pushes and tags the SPM repo (used by CI) |
| `swiftLint.sh` | Installs SwiftLint |
| `addMultiAdLoaderTests.rb` | One-off: adds the `PrebidMultiAdLoaderTests`, `...GAMTests` and `...YandexTests` targets and schemes to `EventHandlers.xcodeproj` and wires the inter-module dependencies |

### Modules covered by the scripts

| Module (Xcode target / SPM target) | CocoaPods pod | Built by `buildPrebidMobile.sh` | Tested by |
| --- | --- | --- | --- |
| `PrebidMobile` | `VeonPrebidMobile` | yes | `testPrebidMobile.sh` |
| `PrebidMobileGAMEventHandlers` | `VeonPrebidMobileGAMEventHandlers` | yes | `testPrebidMobileAdapters.sh` |
| `PrebidMobileAdMobAdapters` | `VeonPrebidMobileAdMobAdapters` | yes | `testPrebidMobileAdapters.sh` |
| `PrebidMobileMAXAdapters` | `VeonPrebidMobileMAXAdapters` | yes | `testPrebidMobileAdapters.sh` |
| `PrebidRemoteConfig` | `VeonPrebidRemoteConfig` | yes | `testPrebidMobileAdapters.sh` (via `PrebidMultiAdLoaderTests`: `SdkConfig`, `RemoteConfigHolder`, `SdkConfigStore`) |
| `PrebidMultiAdLoader` | `VeonPrebidMultiAdLoader` | yes | `testPrebidMobileAdapters.sh` (race engine, registry, banner and interstitial loaders) |
| `PrebidMultiAdLoaderGAM` | `VeonPrebidMultiAdLoaderGAM` | yes | `testPrebidMobileAdapters.sh` (`PrebidMultiAdLoaderGAMTests`, needs `Google-Mobile-Ads-SDK` in the Podfile for the test target) |
| `PrebidMultiAdLoaderYandex` | `VeonPrebidMultiAdLoaderYandex` | yes | `testPrebidMobileAdapters.sh` (`PrebidMultiAdLoaderYandexTests`, needs `YandexMobileAds` in the Podfile for the test target) |

### Checklist: adding a new module

1. Add a framework target to `EventHandlers/EventHandlers.xcodeproj`.
2. Add a shared scheme named `Lib-<Module>` to `EventHandlers/EventHandlers.xcodeproj/xcshareddata/xcschemes`
   (the `Lib-` prefix disambiguates it from the scheme Xcode auto-generates for the SPM library with the same name).
3. Add `<Module>` to the `schemes` array in `buildPrebidMobile.sh`. Keep dependencies **before** dependents.
4. If the module has unit tests, add the test scheme to `test_schemes` in `testPrebidMobileAdapters.sh`.
5. Add the SPM library/target to `Package.swift` and `EventHandlers/Package.swift`, and a `Veon<Module>.podspec`.
6. Update the tables above.
