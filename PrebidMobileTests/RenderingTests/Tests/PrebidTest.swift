/*   Copyright 2018-2021 Prebid.org, Inc.
 
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

import XCTest
@testable @_spi(PBMInternal) import PrebidMobile

class PrebidTest: XCTestCase {
    
    private var logToFile: LogToFileLock?
    
    private var sdkConfiguration: Prebid!
    private let targeting = Targeting.shared
    
    override func setUp() {
        super.setUp()
        sdkConfiguration = Prebid.mock
    }
    
    override func tearDown() {
        Log.logLevel = .debug
        
        logToFile = nil
        sdkConfiguration = nil
        
        Prebid.reset()
        PrebidMobilePluginRegister.shared.unregisterAllPlugins()
        MockDeviceAccessManager.reset()
        
        super.tearDown()
    }
    
    func testInitialValues() {
        let sdkConfiguration = Prebid.shared
        
        checkInitialValue(sdkConfiguration: sdkConfiguration)
    }
    
    func testInitializeSDK_OptionalCallback() throws {
        // init callback should be optional
        let serverURL = "https://prebid-server-test-j.prebid.org/openrtb2/auction"
        try XCTUnwrap(Prebid.initializeSDK(serverURL: serverURL))
    }
    
    func testInitializeSDK() throws {
        
        let serverURL = "https://prebid-server-test-j.prebid.org/openrtb2/auction"
        let expectation = expectation(description: "Expected successful initialization")
        
        try XCTUnwrap(
            Prebid.initializeSDK(serverURL: serverURL) { status, error in
                if case .succeeded = status {
                    expectation.fulfill()
                }
            
                if let error = error {
                    XCTFail("Failed with error: \(error.localizedDescription)")
                }
            }
        )
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testLogLevel() {
        let sdkConfiguration = Prebid.shared
        
        XCTAssertEqual(sdkConfiguration.logLevel, Log.logLevel)
        
        sdkConfiguration.logLevel = .verbose
        XCTAssertEqual(Log.logLevel, .verbose)
        
        Log.logLevel = .warn
        XCTAssertEqual(sdkConfiguration.logLevel, .warn)
    }
    
    func testDebugLogFileEnabled() {
        
        let sdkConfiguration = Prebid.shared
        let initialValue = sdkConfiguration.debugLogFileEnabled
        
        XCTAssertEqual(initialValue, Log.logToFile)
        
        sdkConfiguration.debugLogFileEnabled = !initialValue
        XCTAssertEqual(Log.logToFile, !initialValue)
        
        Log.logToFile = initialValue
        XCTAssertEqual(sdkConfiguration.debugLogFileEnabled, initialValue)
    }
    
    func testLocationValues() {
        let sdkConfiguration = Prebid.shared
        XCTAssertTrue(sdkConfiguration.locationUpdatesEnabled)
        sdkConfiguration.locationUpdatesEnabled = false
        XCTAssertFalse(sdkConfiguration.locationUpdatesEnabled)
    }
    
    func testShared() {
        let firstConfig = Prebid.shared
        let newConfig = Prebid.shared
        XCTAssertEqual(firstConfig, newConfig)
    }
    
    func testResetShared() {
        let firstConfig = Prebid.shared
        firstConfig.prebidServerAccountId = "test"
        Prebid.reset()
        
        checkInitialValue(sdkConfiguration: firstConfig)
    }
    
    func testServerHostCustomOnAuthorizedTrackingStatus() throws {
        //given
        let customTrackingHost = "https://prebid-server.tracking.com/openrtb2/auction"
        let customNonTrackingHost = "https://prebid-server.nontracking.com/openrtb2/auction"
        
        MockDeviceAccessManager.mockAdvertisingTrackingEnabled = true
        if #available(iOS 14, *) {
            MockDeviceAccessManager.mockAppTrackingTransparencyStatus = .authorized
        }
        let host = Host(deviceManager: MockDeviceAccessManager(rootViewController: nil))
        
        //when
        try host.setHostURL(customTrackingHost, nonTrackingURLString: customNonTrackingHost)
        
        //then
        let getHostURLResult = try host.getHostURL()
        XCTAssertEqual(customTrackingHost, getHostURLResult)
    }
    
    func testServerHostCustomOnNonAuthorizedTrackingStatus() throws {
        //given
        let customTrackingHost = "https://prebid-server.tracking.com/openrtb2/auction"
        let customNonTrackingHost = "https://prebid-server.nontracking.com/openrtb2/auction"
        
        MockDeviceAccessManager.mockAdvertisingTrackingEnabled = false
        if #available(iOS 14, *) {
            MockDeviceAccessManager.mockAppTrackingTransparencyStatus = .denied
        }
        let host = Host(deviceManager: MockDeviceAccessManager(rootViewController: nil))
        
        //when
        try host.setHostURL(customTrackingHost, nonTrackingURLString: customNonTrackingHost)
        
        //then
        let getHostURLResult = try host.getHostURL()
        XCTAssertEqual(customNonTrackingHost, getHostURLResult)
    }
    
    func testAccountId() {
        //given
        let serverAccountId = "123"
        
        //when
        Prebid.shared.prebidServerAccountId = serverAccountId
        
        //then
        XCTAssertEqual(serverAccountId, Prebid.shared.prebidServerAccountId)
    }

    func testStoredAuctionResponse() {
        //given
        let storedAuctionResponse = "111122223333"
        
        //when
        Prebid.shared.storedAuctionResponse = storedAuctionResponse
        
        //then
        XCTAssertEqual(storedAuctionResponse, Prebid.shared.storedAuctionResponse)
    }
    
    func testAuctionSettingsId() {
        //given
        let auctionSettingsId = "789"
        
        //when
        Prebid.shared.auctionSettingsId = auctionSettingsId
        
        //then
        XCTAssertEqual(auctionSettingsId, Prebid.shared.auctionSettingsId)
    }
    
    func testAddStoredBidResponse() {
        
        //given
        let appnexusBidder = "appnexus"
        let appnexusResponseId = "221144"
        
        let rubiconBidder = "rubicon"
        let rubiconResponseId = "221155"
        
        //when
        Prebid.shared.addStoredBidResponse(bidder: appnexusBidder, responseId: appnexusResponseId)
        Prebid.shared.addStoredBidResponse(bidder: rubiconBidder, responseId: rubiconResponseId)
        
        //then
        let dict = Prebid.shared.storedBidResponses
        XCTAssertEqual(2, dict.count)
        XCTAssert(dict[appnexusBidder] == appnexusResponseId && dict[rubiconBidder] == rubiconResponseId )
    }
    
    func testClearStoredBidResponses() {
        
        //given
        Prebid.shared.addStoredBidResponse(bidder: "rubicon", responseId: "221155")
        let case1 = Prebid.shared.storedBidResponses.count
        
        //when
        Prebid.shared.clearStoredBidResponses()
        let case2 = Prebid.shared.storedBidResponses.count
        
        //then
        XCTAssertNotEqual(0, case1)
        XCTAssertEqual(0, case2)
    }

    func testAddCustomHeader() {
        
        //given
        let sdkVersionHeader = "X-SDK-Version"
        let bundleHeader = "X-Bundle"

        let sdkVersion = "1.1.666"
        let bundleName = "com.app.nextAd"

        //when
        Prebid.shared.addCustomHeader(name: sdkVersionHeader, value: sdkVersion)
        Prebid.shared.addCustomHeader(name: bundleHeader, value: bundleName)

        //then
        let dict = Prebid.shared.customHeaders
        XCTAssertEqual(2, dict.count)
        XCTAssert(dict[sdkVersionHeader] == sdkVersion && dict[bundleHeader] == bundleName )
    }

    func testClearCustomHeaders() {

        //given
        Prebid.shared.addCustomHeader(name: "header", value: "value")
        let case1 = Prebid.shared.customHeaders.count

        //when
        Prebid.shared.clearCustomHeaders()
        let case2 = Prebid.shared.customHeaders.count

        //then
        XCTAssertNotEqual(0, case1)
        XCTAssertEqual(0, case2)
    }
    
    func testShareGeoLocation() {
        //given
        let case1 = true
        let case2 = false
        
        //when
        Prebid.shared.shareGeoLocation = case1
        let result1 = Prebid.shared.shareGeoLocation
        
        Prebid.shared.shareGeoLocation = case2
        let result2 = Prebid.shared.shareGeoLocation
        
        //rhen
        XCTAssertEqual(case1, result1)
        XCTAssertEqual(case2, result2)
    }
    
    func testTimeoutMillis() {
        //given
        let timeoutMillis =  3_000
        
        //when
        Prebid.shared.timeoutMillis = timeoutMillis
        
        //then
        XCTAssertEqual(timeoutMillis, Prebid.shared.timeoutMillis)
    }
    
    func testPbsDebug() {
        //given
        let pbsDebug = true
        
        //when
        Prebid.shared.pbsDebug = pbsDebug
        
        //then
        XCTAssertEqual(pbsDebug, Prebid.shared.pbsDebug)
    }
    
    func testPBSCreativeFactoryTimeout() {
        try! Host.shared.setHostURL(Prebid.devintServerURL, nonTrackingURLString: nil)
        sdkConfiguration.prebidServerAccountId = Prebid.devintAccountID
        
        let creativeFactoryTimeout = 11.1
        let creativeFactoryTimeoutPreRenderContent = 22.2
        
        let configId = "b6260e2b-bc4c-4d10-bdb5-f7bdd62f5ed4"
        let adUnitConfig = AdUnitConfig(configId: configId, size: CGSize(width: 300, height: 250))
        let connection = MockServerConnection(onPost: [{ (url, data, timeout, callback) in
            callback(PBMBidResponseTransformer.makeValidResponseWithCTF(bidPrice: 0.5, ctfBanner: creativeFactoryTimeout, ctfPreRender: creativeFactoryTimeoutPreRenderContent))
        }])
        
        let requester = Factory.createBidRequester(connection: connection,
                                                   sdkConfiguration: sdkConfiguration,
                                                   targeting: targeting,
                                                   adUnitConfiguration: adUnitConfig)
        
        let exp = expectation(description: "exp")
        requester.requestBids { (bidResponse, error) in
            exp.fulfill()
            if let error = error {
                XCTFail(error.localizedDescription)
                return
            }
            XCTAssertNotNil(bidResponse)
        }
        waitForExpectations(timeout: 5)
        
        XCTAssertEqual(Prebid.shared.creativeFactoryTimeout, creativeFactoryTimeout)
        XCTAssertEqual(Prebid.shared.creativeFactoryTimeoutPreRenderContent, creativeFactoryTimeoutPreRenderContent)
    }
    
    func testRegisterSDKRenderer() throws {
        XCTAssertTrue(PrebidMobilePluginRegister.shared.getAllPlugins().isEmpty)
        
        let serverURL = "https://prebid-server-test-j.prebid.org/openrtb2/auction"
        try XCTUnwrap(Prebid.initializeSDK(serverURL: serverURL))
        
        XCTAssertTrue(PrebidMobilePluginRegister.shared.getAllPlugins().count == 1)
        XCTAssertTrue(PrebidMobilePluginRegister.shared.getAllPlugins().first?.name == PREBID_MOBILE_RENDERER_NAME)
    }
    
    // MARK: - Private Methods
    
    private func checkInitialValue(sdkConfiguration: Prebid, file: StaticString = #file, line: UInt = #line) {
        // PBMSDKConfiguration
        
        XCTAssertEqual(sdkConfiguration.creativeFactoryTimeout, 6.0)
        XCTAssertEqual(sdkConfiguration.creativeFactoryTimeoutPreRenderContent, 30.0)
                
        // Prebid-specific
        
        XCTAssertEqual(sdkConfiguration.prebidServerAccountId, "")
        XCTAssertNil(sdkConfiguration.auctionSettingsId)
    }
}
