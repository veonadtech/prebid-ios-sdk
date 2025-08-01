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

#import "PBMDisplayTransactionFactory.h"

#import "PBMMacros.h"

#import "SwiftImport.h"

@interface PBMDisplayTransactionFactory() <PBMTransactionDelegate>

@property (nonatomic, strong, readonly, nonnull) Bid *bid;
@property (nonatomic, strong, readonly, nonnull) AdUnitConfig *adConfiguration;
@property (nonatomic, strong, readonly, nonnull) id<PrebidServerConnectionProtocol> connection;

// NOTE: need to call the completion callback only in the main thread
// use onFinishedWithTransaction
@property (nonatomic, copy, readonly, nonnull) PBMTransactionFactoryCallback callback;

@property (nonatomic, strong, nullable) id<PBMTransaction> transaction;
@property (nonatomic, readonly) BOOL isLoading;

@end



@implementation PBMDisplayTransactionFactory

// MARK: - Public API

- (instancetype)initWithBid:(Bid *)bid
            adConfiguration:(AdUnitConfig *)adConfiguration
                 connection:(id<PrebidServerConnectionProtocol>)connection
                   callback:(PBMTransactionFactoryCallback)callback
{
    if (!(self = [super init])) {
        return nil;
    }
    _bid = bid;
    _adConfiguration = adConfiguration;
    _connection = connection;
    _callback = [callback copy];
    return self;
}

- (BOOL)loadWithAdMarkup:(NSString *)adMarkup {
    if (self.isLoading) {
        return NO;
    }
    
    [self loadHTMLTransaction:adMarkup];
    
    return YES;
}

// MARK: - PBMTransactionDelegate protocol

- (void)transactionReadyForDisplay:(id<PBMTransaction>)transaction {
    self.transaction = nil;
    [self onFinishedWithTransaction:transaction error:nil];
}

- (void)transactionFailedToLoad:(id<PBMTransaction>)transaction error:(NSError *)error {
    self.transaction = nil;
    [self onFinishedWithTransaction:nil error:error];
}

// MARK: - Private Helpers

- (BOOL)isLoading {
    return (self.transaction != nil);
}

- (void)loadHTMLTransaction:(NSString *)adMarkup {
    NSMutableArray<PBMCreativeModel *> * const creativeModels = [[NSMutableArray alloc] init];
    
    [creativeModels addObject:[self htmlCreativeModelFromBid:self.bid
                                                    adMarkup:adMarkup
                                             adConfiguration:self.adConfiguration]];
    
    self.transaction = [PBMFactory createTransactionWithServerConnection:self.connection
                                                         adConfiguration:self.adConfiguration.adConfiguration
                                                                  models:creativeModels];
    
    self.transaction.bid = self.bid;
    
    self.transaction.delegate = self;
    [self.transaction startCreativeFactory];
}

- (PBMCreativeModel *)htmlCreativeModelFromBid:(Bid *)bid
                                      adMarkup:(NSString *)adMarkup
                               adConfiguration:(AdUnitConfig *)adConfiguration {
    PBMCreativeModel * const model = [[PBMCreativeModel alloc] initWithAdConfiguration:adConfiguration.adConfiguration];
    
    model.html = adMarkup;
    model.width = bid.size.width;
    model.height = bid.size.height;
    return model;
}

- (void)onFinishedWithTransaction:(id<PBMTransaction>)transaction error:(NSError *)error {
    @weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        if (!self) { return; }
        self.callback(transaction, error);
    });
}

@end
