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
#import "PBMDownloadDataHelper.h"

@protocol PrebidServerConnectionProtocol;
@protocol PBMTransaction;
@protocol PBMAbstractCreative;

typedef void(^PBMCreativeFactoryFinishedCallback)(NSArray<id<PBMAbstractCreative>> * _Nullable, NSError * _Nullable);
typedef void(^PBMCreativeFactoryDownloadDataCompletionClosure)(NSURL* _Nonnull, PBMDownloadDataCompletionClosure _Nonnull);

@interface PBMCreativeFactory : NSObject

- (nonnull instancetype)init NS_UNAVAILABLE;
- (nonnull instancetype)initWithServerConnection:(nonnull id<PrebidServerConnectionProtocol>)serverConnection
                                     transaction:(nonnull id<PBMTransaction>)transaction
                                finishedCallback:(nonnull PBMCreativeFactoryFinishedCallback)finishedCallback
NS_DESIGNATED_INITIALIZER;

- (void)startFactory;

@end


