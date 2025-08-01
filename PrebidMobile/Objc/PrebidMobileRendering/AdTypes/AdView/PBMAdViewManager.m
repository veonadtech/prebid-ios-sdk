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

#import "PBMAdLoadManagerProtocol.h"
#import "PBMFunctions+Private.h"
#import "PBMInterstitialLayoutConfigurator.h"
#import "PBMVideoCreative.h"
#import "UIView+PBMExtensions.h"

#import "PBMMacros.h"
#import "Log+Extensions.h"

#import "SwiftImport.h"

@interface PBMAdViewManager_Objc: NSObject <PBMAdViewManager>

@property (nonatomic, strong) id<PrebidServerConnectionProtocol> serverConnection;
@property (nonatomic, weak, nullable)  id<PBMAbstractCreative> currentCreative;
@property (nonatomic, strong, nullable) id<PBMTransaction> externalTransaction;
@property (nonatomic, nullable, readonly) id<PBMTransaction> currentTransaction; // computed
@property (nonatomic, assign) BOOL videoInterstitialDidClose;

@end

@implementation PBMAdViewManager_Objc
@synthesize adConfiguration = _adConfiguration;
@synthesize adViewManagerDelegate = _adViewManagerDelegate;
@synthesize autoDisplayOnLoad = _autoDisplayOnLoad;
@synthesize modalManager = _modalManager;

- (instancetype)initWithConnection:(id<PrebidServerConnectionProtocol>)connection
              modalManagerDelegate:(nullable id<PBMModalManagerDelegate>)modalManagerDelegate
{
    if (!(self = [super init])) {
        return nil;
    }
        
    PBMAssert(connection);
    
    _autoDisplayOnLoad = YES;
    _serverConnection = connection;
    _modalManager = [[PBMModalManager alloc] initWithDelegate:modalManagerDelegate];
    _adConfiguration = [PBMAdConfiguration new];
    _videoInterstitialDidClose = NO;
    
    return self;
}

#pragma mark - API

- (NSString *)revenueForNextCreative {
    return [self.currentTransaction revenueForCreativeAfter:self.currentCreative];
}

- (BOOL)isAbleToShowCurrentCreative {
    if (!self.currentCreative) {
        PBMLogError(@"No creative to display");
        return NO;
    }
    
    if ([self isInterstitial] && ![self.adViewManagerDelegate viewControllerForModalPresentation]) {
        PBMLogError(@"viewControllerForModalPresentation returned nil");
        return NO;
    }
    
    return YES;
}

- (void)show {
    if (![self isAbleToShowCurrentCreative]) {
        return;
    }
    
    UIViewController* viewController = [self.adViewManagerDelegate viewControllerForModalPresentation];
    if (!viewController) {
        PBMLogError(@"viewControllerForModalPresentation is nil. Check the implementation of Ad View Delegate.");
        return;
    }
    
    self.currentCreative.creativeViewDelegate = self;
    
    if ([self isInterstitial]) {
        PBMInterstitialDisplayProperties* displayProperties = [self.adViewManagerDelegate interstitialDisplayProperties];
        
        //set interstitial display properties from ad configuration parameters
        [PBMInterstitialLayoutConfigurator configurePropertiesWithAdConfiguration:self.adConfiguration displayProperties:displayProperties];
        //we need to force orientation if device is not in the expected one
        if (displayProperties.interstitialLayout == PBMInterstitialLayoutLandscape) {
            [self.modalManager forceOrientation:UIInterfaceOrientationLandscapeLeft];
        } else if (displayProperties.interstitialLayout == PBMInterstitialLayoutPortrait) {
            [self.modalManager forceOrientation:UIInterfaceOrientationPortrait];
        }
        [self.currentCreative showAsInterstitialFromRootViewController:viewController displayProperties:displayProperties];
    } else {
        UIView* creativeView = self.currentCreative.view;
        if (!creativeView) {
            PBMLogError(@"Creative has no view");
            return;
        }
        
        @weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if (!self) { return; }
            
            [[self.adViewManagerDelegate displayView] addSubview:creativeView];
            [self.currentCreative displayWithRootViewController:viewController];
        });
    }
}

- (void)pause {
    [self.currentCreative pause];
}

- (void)resume {
    [self.currentCreative resume];
}

- (void)mute {
    [self.currentCreative mute];
}

- (void)unmute {
    [self.currentCreative unmute];
}

- (BOOL)isMuted {
    return [self.currentCreative isMuted];
}

- (void)handleExternalTransaction:(id<PBMTransaction>)transaction {
    self.externalTransaction = transaction;
    [self onTransactionIsReady:transaction];
}

#pragma mark - PBMCreativeViewDelegate

- (void)videoCreativeDidComplete:(id<PBMAbstractCreative>)creative {
    if ([self.adViewManagerDelegate respondsToSelector:@selector(videoAdDidFinish)]) {
        [self.adViewManagerDelegate videoAdDidFinish];
    }
}

- (void)videoWasMuted:(id<PBMAbstractCreative>)creative {
    if ([self.adViewManagerDelegate respondsToSelector:@selector(videoAdWasMuted)]) {
        [self.adViewManagerDelegate videoAdWasMuted];
    }
}

- (void)videoWasUnmuted:(id<PBMAbstractCreative>)creative {
    if ([self.adViewManagerDelegate respondsToSelector:@selector(videoAdWasUnmuted)]) {
        [self.adViewManagerDelegate videoAdWasUnmuted];
    }
}

- (void)creativeDidComplete:(id<PBMAbstractCreative>)creative {
    PBMLogWhereAmI();
    
    if (!self.adConfiguration.isBuiltInVideo && self.currentCreative.view && self.currentCreative.view.superview) {
        [self.currentCreative.view removeFromSuperview];
    }
    
    //When a creative completes, show the next one in the transaction
    id<PBMTransaction> const transaction = self.currentTransaction;
     id<PBMAbstractCreative> nextCreative = [transaction getCreativeAfter:self.currentCreative];
    if (nextCreative && !self.videoInterstitialDidClose) {
        [self setupCreative:nextCreative];
        return;
    }
    
    // In the case of 300x250 video, the finish of playback does not mean the completion of the ad.
    // User could Watch Again the same creative so it still should be alive. 
    if (self.adConfiguration.isBuiltInVideo) {
        return;
    }
    
    //If there is no next creative, the transaction is complete.
    [self.adViewManagerDelegate adDidComplete];
}

- (void)creativeDidDisplay:(id<PBMAbstractCreative>)creative {
    self.videoInterstitialDidClose = NO;
    [self.adViewManagerDelegate adDidDisplay];
}

- (void)creativeWasClicked:(id<PBMAbstractCreative>)creative {
    [self.adViewManagerDelegate adWasClicked];
}

- (void)creativeInterstitialDidClose:(id<PBMAbstractCreative>) creative {
    if (self.adConfiguration.winningBidAdFormat == AdFormat.video) {
        self.videoInterstitialDidClose = YES;
    }
    
    [self.adViewManagerDelegate adDidClose];
}

- (void)creativeInterstitialDidLeaveApp:(id<PBMAbstractCreative>) creative {
    [self.adViewManagerDelegate adDidLeaveApp];
}

- (void)creativeClickthroughDidClose:(id<PBMAbstractCreative>) creative {
    [self.adViewManagerDelegate adClickthroughDidClose];
}

- (void)creativeMraidDidCollapse:(id<PBMAbstractCreative>) creative {
    [self.adViewManagerDelegate adDidCollapse];
}

- (void)creativeMraidDidExpand:(id<PBMAbstractCreative>) creative {
    [self.adViewManagerDelegate adDidExpand];
}

//TODO: Describe what implanting means
- (void)creativeReadyToReimplant:(id<PBMAbstractCreative>)creative {
    UIView *creativeView = creative.view;
    if (!creativeView) {
        return;
    }
    
    if (![self isInterstitial]) {
        [self.adViewManagerDelegate.displayView addSubview:creativeView];
    }
    
    [creativeView PBMAddFillSuperviewConstraints];
}

- (void)creativeViewWasClicked:(id<PBMAbstractCreative>)creative {
    // POTENTIAL BUG: if publisher did not provide the controller for modal presentation
    // and we did not check it before 'show'
    // the video will disappear from UI and won't appear in the interstitial controller.
    if ([self isAbleToShowCurrentCreative] && !self.adConfiguration.presentAsInterstitial) {
        // IMPORTANT: we have to remove PBMVideoAdView from super view before invoking the show method.
        // Otherwise, the video won't be displayed.
        
        [self.currentCreative.view removeFromSuperview];
        
        self.adConfiguration.forceInterstitialPresentation = @(YES);
        [self.currentCreative.eventManager trackEvent:PBMTrackingEventExpand];
        [self show];
        
        [self.adViewManagerDelegate adViewWasClicked];
    }
}

- (void)creativeFullScreenDidFinish:(id<PBMAbstractCreative>)creative {
    self.adConfiguration.forceInterstitialPresentation = nil;
    self.currentCreative.creativeModel.adConfiguration.forceInterstitialPresentation = nil;
    [self.currentCreative.eventManager trackEvent:PBMTrackingEventNormal];
    
    [self.adViewManagerDelegate.displayView addSubview:self.currentCreative.view];
    
    [self.currentCreative displayWithRootViewController:[self.adViewManagerDelegate viewControllerForModalPresentation]];
    
    [self.adViewManagerDelegate adDidClose];
}

/// NOTE: Rewarded API only
- (void)creativeDidSendRewardedEvent:(id<PBMAbstractCreative>)creative {
    if (self.isInterstitial && self.isRewarded) {
        [self.adViewManagerDelegate adDidSendRewardedEvent];
    }
}

#pragma mark - Utility Functions

- (id<PBMTransaction>)currentTransaction {
    return self.externalTransaction;
}

- (BOOL)isInterstitial {
    return self.adConfiguration.presentAsInterstitial;
}

- (BOOL)isRewarded {
    return self.adConfiguration.isRewarded;
}

//Do not load an ad if the current one is "opened"
//Is the current creative an PBMHTMLCreative? If so, is a clickthrough browser visible/MRAID in Expanded mode?
- (BOOL)isCreativeOpened {
    
    id<PBMTransaction> const transaction = self.currentTransaction;
    if (transaction == nil) {
        return NO;
    }
    
    //TODO: When is there ever a transaction but no current creative?
    if (!self.currentCreative) {
        return NO;
    }
    
    BOOL ret = self.currentCreative.isOpened;
    return ret;
}

// Changes self.creative and calls show & setupRefreshTimer if possible.
- (void)setupCreative:(id<PBMAbstractCreative>)creative {
    [self setupCreative:creative withThread:NSThread.currentThread];
}

- (void)setupCreative:(id<PBMAbstractCreative>)creative withThread:(id<PBMThreadProtocol>)thread {
    if (!thread.isMainThread) {
        PBMLogError(@"setupCreative must be called on the main thread");
        return;
    }
    
    id<PBMTransaction> const transaction = self.currentTransaction;
    self.currentCreative.view.hidden = YES;
    self.currentCreative = creative;
    self.adConfiguration = creative.creativeModel.adConfiguration;
    self.autoDisplayOnLoad = !self.currentCreative.creativeModel.adConfiguration.isInterstitialAd;
    if (self.autoDisplayOnLoad || self.currentCreative != [transaction getFirstCreative]) {
        [self show];
    }
}

#pragma mark - Internal Methods

- (void)onTransactionIsReady:(id<PBMTransaction>)transaction {
    for ( id<PBMAbstractCreative> creative in transaction.creatives) {
        creative.modalManager = self.modalManager;
    }
        
    //TODO need __block modifier on transaction?
    @weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        
        if (!self) { return; }
        
        //If we're currently displaying a creative, bail.
        if (self.currentCreative) {
            return;
        }
        
        //Otherwise attempt to show the creative.
        [self setupCreative:[transaction getFirstCreative]];
        
        [self.adViewManagerDelegate adLoaded:[transaction getAdDetails]];
    });
}

@end
