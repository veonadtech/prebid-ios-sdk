if [ -d "scripts" ]; then
cd scripts/
fi

usage() {
  cat <<'USAGE'
Usage: testPrebidMobileAdapters.sh
USAGE
}

set -e

GREEN='\033[0;32m'
NC='\033[0m' # No Color

SIMULATOR_NAME="iPhone-16-Pro-PrebidMobile"

# Test schemes of the modules that live in EventHandlers/EventHandlers.xcodeproj.
# To cover a new module: add its unit-test scheme here (see scripts/addMultiAdLoaderTests.rb
# for an example of how a test target for a new module is created).
#
#   PrebidMobileGAMEventHandlersTests  - GAM event handlers
#   PrebidMobileAdMobAdaptersTests     - AdMob mediation adapters
#   PrebidMobileMAXAdaptersTests       - AppLovin MAX mediation adapters
#   PrebidMultiAdLoaderTests           - VeonPrebidRemoteConfig + VeonPrebidMultiAdLoader (config parsing, race engine,
#                                        source registry, banner / interstitial loaders, built-in Prebid sources)
#   PrebidMultiAdLoaderGAMTests        - VeonPrebidMultiAdLoaderGAM (needs GoogleMobileAds linked via the Podfile)
#   PrebidMultiAdLoaderYandexTests     - VeonPrebidMultiAdLoaderYandex (needs YandexMobileAds linked via the Podfile)
test_schemes=(
    "PrebidMobileGAMEventHandlersTests"
    "PrebidMobileAdMobAdaptersTests"
    "PrebidMobileMAXAdaptersTests"
    "PrebidMultiAdLoaderTests"
    "PrebidMultiAdLoaderGAMTests"
    "PrebidMultiAdLoaderYandexTests"
)

echo -e "\n\n${GREEN}INSTALL PODS${NC}\n\n"

cd ..

export PATH="/Users/distiller/.gem/ruby/2.7.0/bin:$PATH"
gem install cocoapods
pod install --repo-update

echo -e "\n\n${GREEN}RUN PREBID MOBILE ADAPTER TESTS${NC}\n\n"

echo -e "\n${GREEN}Creating simulator${NC} \n"
xcrun simctl create "${SIMULATOR_NAME}" com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro

# Always remove the simulator, also when a test run fails half way through.
cleanup_simulator() {
    xcrun simctl delete "${SIMULATOR_NAME}" >/dev/null 2>&1 || true
}
trap cleanup_simulator EXIT

echo -e "\n${GREEN}Clean build\n"
xcodebuild clean build

function testAdapters () {
  local SCHEME="$1"

    xcodebuild \
        -workspace PrebidMobile.xcworkspace \
        -scheme "${SCHEME}" \
        -sdk iphonesimulator \
        -configuration Debug \
        -destination "platform=iOS Simulator,name=${SIMULATOR_NAME},OS=latest" \
        -destination-timeout 60 \
        build-for-testing || return 1

    xcodebuild \
        -workspace PrebidMobile.xcworkspace \
        -scheme "${SCHEME}" \
        -sdk iphonesimulator \
        -destination "platform=iOS Simulator,name=${SIMULATOR_NAME},OS=latest" \
        -destination-timeout 60 \
        test-without-building || return 1
}

for scheme in "${test_schemes[@]}"
do
    echo -e "\n${GREEN}Running ${scheme} unit tests${NC} \n"

    if testAdapters "${scheme}"; then
        echo "✅ ${scheme} Unit Tests Passed"
    else
        echo "🔴 ${scheme} Unit Tests Failed"
        exit 1
    fi
done

echo -e "\n${GREEN}Removing simulator${NC} \n"
cleanup_simulator
