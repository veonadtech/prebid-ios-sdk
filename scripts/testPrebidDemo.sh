if [ -d "scripts" ]; then
cd scripts/
fi

GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "\n\n${GREEN}RUN PREBID DEMO TESTS${NC}\n\n"

SIMULATOR_NAME="iPhone-16-Pro-PrebidMobile"

# Delete any old simulator left over from a previous run.
# `xcrun simctl delete` accepts a name and removes ALL matching devices,
# so even if duplicates have accumulated, they will all be deleted.
echo -e "\n${GREEN}Cleaning up old simulator if exists${NC} \n"
xcrun simctl delete "${SIMULATOR_NAME}" >/dev/null 2>&1 || true

# Create a fresh simulator and capture its UDID.
# Using the UDID instead of the name prevents the "multiple devices matched
# the request" error when several simulators share the same name.
echo -e "\n${GREEN}Creating simulator${NC} \n"
SIMULATOR_UDID=$(xcrun simctl create "${SIMULATOR_NAME}" com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro)
echo "Simulator UDID: ${SIMULATOR_UDID}"

# Always remove the simulator on exit — even if the script fails halfway through.
cleanup_simulator() {
    echo -e "\n${GREEN}Removing simulator${NC} \n"
    xcrun simctl delete "${SIMULATOR_UDID}" >/dev/null 2>&1 || true
}
trap cleanup_simulator EXIT

cd ..
echo $PWD

export PATH="/Users/distiller/.gem/ruby/2.7.0/bin:$PATH"
gem install cocoapods

pod deintegrate
pod install --repo-update

# NOTE: `pod update` is intentionally omitted here.
# It ignores Podfile.lock and may pull incompatible pod versions
# (for example, a YandexMobileAds build compiled with a different Swift
# version), which breaks the build. Versions must be pinned in Podfile.lock.

if [ "$1" == "-ui" ]; then
    echo -e "\n${GREEN}Running UI tests${NC} \n"
    SCHEME="PrebidDemoSwiftUITests"
    TEST="UI"
else
    echo -e "\n${GREEN}Running integration tests${NC} \n"
    SCHEME="PrebidDemoTests"
    TEST="Integration"
fi

echo -e "\n\n${GREEN}Building ${SCHEME} for testing${NC}\n\n"

xcodebuild \
    -workspace PrebidMobile.xcworkspace \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=${SIMULATOR_UDID}" \
    -destination-timeout 60 \
    build-for-testing

if [[ ${PIPESTATUS[0]} != 0 ]]; then
    echo "🔴 Failed to build ${SCHEME} for testing"
    exit 1
fi

echo -e "\n\n${GREEN}Testing ${SCHEME}${NC}\n\n"

xcodebuild \
    -workspace PrebidMobile.xcworkspace \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=${SIMULATOR_UDID}" \
    -destination-timeout 60 \
    -test-iterations 2 \
    -retry-tests-on-failure \
    test-without-building

if [[ ${PIPESTATUS[0]} == 0 ]]; then
    echo "✅ ${TEST} Tests Passed"
else
    echo "🔴 ${TEST} Tests Failed"
    exit 1
fi

# The simulator is removed automatically via the `trap cleanup_simulator EXIT`,
# so no explicit `xcrun simctl delete` is needed at the end.