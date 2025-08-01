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

#import "PBMVastCreativeNonLinearAds.h"

#import "SwiftImport.h"

@implementation PBMVastCreativeNonLinearAds

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.nonLinears = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Public

-(void)copyTracking:(PBMVastCreativeNonLinearAds *)fromNonLinearAds {
    if (!fromNonLinearAds) {
        return;
    }
    
    for (PBMVastCreativeNonLinearAdsNonLinear *fromNonLinear in fromNonLinearAds.nonLinears) {
        for (PBMVastCreativeNonLinearAdsNonLinear *toNonLinear in self.nonLinears) {
            [toNonLinear.clickTrackingURIs addObjectsFromArray:fromNonLinear.clickTrackingURIs];
            [toNonLinear.vastTrackingEvents addTrackingEvents:fromNonLinear.vastTrackingEvents];
        }
    }
}

@end
