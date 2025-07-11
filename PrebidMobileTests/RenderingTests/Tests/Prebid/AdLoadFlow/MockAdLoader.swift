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

import Foundation
import XCTest

@testable @_spi(PBMInternal) import PrebidMobile

class MockAdLoader: NSObject, AdLoaderProtocol {
    enum ExpectedCall {
        case getFlowDelegate(provider: ()->AdLoaderFlowDelegate?)
        case setFlowDelegate(handler: (AdLoaderFlowDelegate?)->())
        case primaryAdRequester(provider: ()->PrimaryAdRequesterProtocol)
        case createPrebidAd(handler: (Bid, AdUnitConfig, (AnyObject)->(), (@escaping ()->())->())->())
        case reportSuccess(handler: (AnyObject, NSValue?)->())
    }
    
    private let expectedCalls: [ExpectedCall]
    private var nextCallIndex = 0
    private let syncQueue = DispatchQueue(label: "MockAdLoader")
    
    private let file: StaticString
    private let line: UInt
    
    init(expectedCalls: [ExpectedCall], file: StaticString = #file, line: UInt = #line) {
        self.expectedCalls = expectedCalls
        self.file = file
        self.line = line
    }
    
    // MARK: - PBMAdLoaderProtocol
    
    var flowDelegate: AdLoaderFlowDelegate? {
        get {
            let provider: (()->AdLoaderFlowDelegate?)? = syncQueue.sync {
                guard nextCallIndex < expectedCalls.count else {
                    XCTFail("[MockAdLoader] Call index out of bounds: \(nextCallIndex) < \(expectedCalls.count)",
                            file: file, line: line)
                    return nil
                }
                switch expectedCalls[nextCallIndex] {
                case .getFlowDelegate(let provider):
                    nextCallIndex += 1
                    return provider
                default:
                    XCTFail("[MockAdLoader] 'getFlowDelegate' called while expecting for '\(expectedCalls[nextCallIndex])'",
                            file: file, line: line)
                    return nil
                }
            }
            return provider?()
        }
        set {
            let handler: ((AdLoaderFlowDelegate?)->())? = syncQueue.sync {
                guard nextCallIndex < expectedCalls.count else {
                    XCTFail("[MockAdLoader] Call index out of bounds: \(nextCallIndex) < \(expectedCalls.count)",
                            file: file, line: line)
                    return nil
                }
                switch expectedCalls[nextCallIndex] {
                case .setFlowDelegate(let handler):
                    nextCallIndex += 1
                    return handler
                default:
                    XCTFail("[MockAdLoader] 'setFlowDelegate' called while expecting for '\(expectedCalls[nextCallIndex])'",
                            file: file, line: line)
                    return nil
                }
            }
            handler?(newValue)
        }
    }
    
    var primaryAdRequester: PrimaryAdRequesterProtocol? {
        let provider: (()->PrimaryAdRequesterProtocol)? = syncQueue.sync {
            guard nextCallIndex < expectedCalls.count else {
                XCTFail("[MockAdLoader] Call index out of bounds: \(nextCallIndex) < \(expectedCalls.count)",
                        file: file, line: line)
                return nil
            }
            switch expectedCalls[nextCallIndex] {
            case .primaryAdRequester(let provider):
                nextCallIndex += 1
                return provider
            default:
                XCTFail("[MockAdLoader] 'primaryAdRequester' called while expecting for '\(expectedCalls[nextCallIndex])'",
                        file: file, line: line)
                return nil
            }
        }
        return provider?() ?? MockPrimaryAdRequester(expectedCalls: [], file: file, line: line)
    }
    
    func createPrebidAd(with bid: Bid, adUnitConfig: AdUnitConfig, adObjectSaver: @escaping (AnyObject) -> Void, loadMethodInvoker: @escaping (@escaping VoidBlock) -> Void) {
        let handler: ((Bid, AdUnitConfig, (AnyObject)->(), (@escaping ()->())->())->())? = syncQueue.sync {
            guard nextCallIndex < expectedCalls.count else {
                XCTFail("[MockAdLoader] Call index out of bounds: \(nextCallIndex) < \(expectedCalls.count)",
                        file: file, line: line)
                return nil
            }
            switch expectedCalls[nextCallIndex] {
            case .createPrebidAd(let handler):
                nextCallIndex += 1
                return handler
            default:
                XCTFail("[MockAdLoader] 'createPrebidAd' called while expecting for '\(expectedCalls[nextCallIndex])'",
                        file: file, line: line)
                return nil
            }
        }
        handler?(bid, adUnitConfig, adObjectSaver, loadMethodInvoker)
    }
    
    func reportSuccess(with adObject: AnyObject, adSize: NSValue?) {
        let handler: ((AnyObject, NSValue?)->())? = syncQueue.sync {
            guard nextCallIndex < expectedCalls.count else {
                XCTFail("[MockAdLoader] Call index out of bounds: \(nextCallIndex) < \(expectedCalls.count)",
                        file: file, line: line)
                return nil
            }
            switch expectedCalls[nextCallIndex] {
            case .reportSuccess(let handler):
                nextCallIndex += 1
                return handler
            default:
                XCTFail("[MockAdLoader] 'reportSuccess' called while expecting for '\(expectedCalls[nextCallIndex])'",
                        file: file, line: line)
                return nil
            }
        }
        handler?(adObject, adSize)
    }
}

extension MockAdLoader.ExpectedCall: CustomStringConvertible {
    var description: String {
        switch self {
        case .getFlowDelegate:      return "getFlowDelegate"
        case .setFlowDelegate:      return "setFlowDelegate"
        case .primaryAdRequester:   return "primaryAdRequester"
        case .createPrebidAd:       return "createPrebidAd"
        case .reportSuccess:        return "reportSuccess"
        }
    }
}

extension MockAdLoader.ExpectedCall {
    func addingPrefixAction(_ prefixAction: @escaping ()->())->Self {
        switch self {
        case .getFlowDelegate(let provider):
            return .getFlowDelegate(provider: {
                prefixAction()
                return provider()
            })
        case .setFlowDelegate(let handler):
            return .setFlowDelegate(handler: {
                prefixAction()
                handler($0)
            })
        case .primaryAdRequester(let provider):
            return .primaryAdRequester(provider: {
                prefixAction()
                return provider()
            })
        case .createPrebidAd(let handler):
            return .createPrebidAd(handler: {
                prefixAction()
                handler($0, $1, $2, $3)
            })
        case .reportSuccess(let handler):
            return .reportSuccess(handler: {
                prefixAction()
                handler($0, $1)
            })
        }
    }
}
