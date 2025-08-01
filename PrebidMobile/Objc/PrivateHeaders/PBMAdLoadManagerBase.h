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

#import <Foundation/Foundation.h>

#import "PBMAdLoadManagerDelegate.h"
#import "PBMAdLoadManagerProtocol.h"

#import "SwiftImport.h"

NS_ASSUME_NONNULL_BEGIN
@interface PBMAdLoadManagerBase : NSObject <PBMAdLoadManagerProtocol>

@property (nonatomic, weak, nullable) id<PBMAdLoadManagerDelegate> adLoadManagerDelegate;
@property (nonatomic, strong) id<PrebidServerConnectionProtocol> connection;
@property (nonatomic, strong) PBMAdConfiguration *adConfiguration;
@property (nonatomic, strong) Bid *bid;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithBid:(Bid *)bid
                 connection:(id<PrebidServerConnectionProtocol>)connection
            adConfiguration:(PBMAdConfiguration *)adConfiguration NS_DESIGNATED_INITIALIZER;

- (void)makeCreativesWithCreativeModels:(NSArray<PBMCreativeModel *> *)creativeModels;

- (void)requestCompletedFailure:(NSError *)error;

@end
NS_ASSUME_NONNULL_END
