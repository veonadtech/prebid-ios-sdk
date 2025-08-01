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

#import "PBMORTBUser.h"
#import "PBMORTBAbstract+Protected.h"

#import "PBMORTBGeo.h"

#import "SwiftImport.h"

@implementation PBMORTBUser

- (instancetype)init {
    if (!(self = [super init])) {
        return nil;
    }
    _geo = [[PBMORTBGeo alloc] init];
    _ext = [[NSMutableDictionary<NSString *, NSObject *> alloc] init];
    
    return self;
}

- (nonnull PBMJsonDictionary *)toJsonDictionary {
    PBMMutableJsonDictionary *ret = [[PBMMutableJsonDictionary alloc] init];
    
    ret[@"keywords"] = self.keywords;
    ret[@"customdata"] = self.customdata;
    ret[@"id"] = self.userid;
    
    if (self.geo.lat && self.geo.lon) {
        ret[@"geo"] = [self.geo toJsonDictionary];
    }
    
    if(self.data) {
        NSMutableArray<PBMJsonDictionary *> *dataArray = [NSMutableArray<PBMJsonDictionary *> new];
        for (PBMORTBContentData *dataObject in self.data) {
            [dataArray addObject:[dataObject toJsonDictionary]];
        }
        
        ret[@"data"] = dataArray;
    }

    if (self.ext && self.ext.count) {
        ret[@"ext"] = self.ext;
    }
    
    ret = [ret pbmCopyWithoutEmptyVals];
    
    return ret;
}

- (instancetype)initWithJsonDictionary:(nonnull PBMJsonDictionary *)jsonDictionary {
    if (!(self = [self init])) {
        return nil;
    }
    
    _keywords    = jsonDictionary[@"keywords"];
    _customdata  = jsonDictionary[@"customdata"];
    _ext         = jsonDictionary[@"ext"];
    _userid      = jsonDictionary[@"id"];
        
    _geo = [[PBMORTBGeo alloc] initWithJsonDictionary:jsonDictionary[@"geo"]];
    
    NSMutableArray<PBMORTBContentData *> *dataArray = [NSMutableArray<PBMORTBContentData *> new];
    NSMutableArray<PBMJsonDictionary *> *dataDicts = jsonDictionary[@"data"];
    if (dataDicts.count > 0) {
        for (PBMJsonDictionary *dataDict in dataDicts) {
            if (dataDict && [dataDict isKindOfClass:[NSDictionary class]])
                [dataArray addObject:[[PBMORTBContentData alloc] initWithJsonDictionary:dataDict]];
        }
        
        _data = dataArray;
    }
    
    return self;
}

- (void)appendEids:(NSArray<NSDictionary<NSString *, id> *> *)eids {
    
    if (!self.ext[@"eids"]) {
        self.ext[@"eids"] = eids;
    } else {
        NSArray *currentEids = (NSArray<NSDictionary<NSString *, id> *> *)self.ext[@"eids"];
        
        self.ext[@"eids"] = [currentEids arrayByAddingObjectsFromArray:eids];
    }
}


@end
