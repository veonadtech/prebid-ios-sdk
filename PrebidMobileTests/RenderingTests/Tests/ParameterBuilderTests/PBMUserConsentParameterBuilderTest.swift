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
@testable import PrebidMobile

class PBMUserConsentParameterBuilderTest: XCTestCase {
    
    override func tearDown() {
        UserConsentDataManager.shared.reset()
        super.tearDown()
    }
    
    func testInit() {
        let builder = PBMUserConsentParameterBuilder()
        XCTAssertNotNil(builder)
    }
    
    func testBuilderNotSubjectToGDPR() {
        UserConsentDataManager.shared.subjectToGDPR = false
        UserConsentDataManager.shared.gdprConsentString = "consentstring"
        
        let builder = PBMUserConsentParameterBuilder()
        
        let bidRequest = PBMORTBBidRequest()
        builder.build(bidRequest)
        
        XCTAssertEqual(bidRequest.regs.ext?["gdpr"] as? Int, 0)
        XCTAssertEqual(bidRequest.user.ext?["consent"] as? String, "consentstring")
    }
    
    func testBuilderSubjectToGDPR() {
        UserConsentDataManager.shared.subjectToGDPR = true
        UserConsentDataManager.shared.gdprConsentString = "differentconsentstring"
        
        let builder = PBMUserConsentParameterBuilder()
        
        let bidRequest = PBMORTBBidRequest()
        builder.build(bidRequest)
        
        XCTAssertEqual(bidRequest.regs.ext?["gdpr"] as? Int, 1)
        XCTAssertEqual(bidRequest.user.ext?["consent"] as? String, "differentconsentstring")
    }
    
}
