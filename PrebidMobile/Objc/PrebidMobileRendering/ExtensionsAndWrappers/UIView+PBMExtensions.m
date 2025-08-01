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

#import <UIKit/UIKit.h>

#import "UIView+PBMExtensions.h"
#import "UIView+PBMViewExposure.h"
#import "Log+Extensions.h"

#import "SwiftImport.h"

@implementation UIView (PBMExtensions)


#pragma mark - Extensions

- (void)PBMAddCropAndCenterConstraintsWithInitialWidth:(CGFloat)initialWidth initialHeight:(CGFloat)initialHeight {
    if (!self.superview) {
        return;
    }
    
    self.translatesAutoresizingMaskIntoConstraints = false;

    //Required Priority: Centering
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    
    //Required Priority: "Be smaller than superView dimensions"
    NSLayoutConstraint *smallerThanSuperviewWidth = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.superview attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    NSLayoutConstraint *smallerThanSuperviewHeight = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.superview attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
    
    //High Priority: "Be no greater than initial dimensions"
    NSLayoutConstraint *noLargerThanInitialWidth = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:initialWidth];
    noLargerThanInitialWidth.priority = 750;
    
    NSLayoutConstraint *noLargerThanInitialHeight = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:initialHeight];
    noLargerThanInitialHeight.priority = 750;

    NSArray *constraints = @[centerX, centerY, smallerThanSuperviewWidth, smallerThanSuperviewHeight, noLargerThanInitialWidth, noLargerThanInitialHeight];
    [self activateConstraints:constraints];
    [self.superview addConstraints:constraints];
}

- (void)PBMAddBottomRightConstraintsWithMarginSize:(CGSize)marginSize {
    if (!self.superview) {
        return;
    }
    
    self.translatesAutoresizingMaskIntoConstraints = false;
    
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeRight multiplier:1.0 constant:marginSize.width];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:marginSize.height];

    NSArray *constraints = @[right, bottom];
    [self activateConstraints:constraints];
    [self.superview addConstraints:constraints];
}

- (void)PBMAddBottomRightConstraintsWithViewSize:(CGSize)viewSize marginSize:(CGSize)marginSize {
    if (!self.superview) {
        return;
    }
    
    self.translatesAutoresizingMaskIntoConstraints = false;
    
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:viewSize.width];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:viewSize.height];
    
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeRight multiplier:1.0 constant:marginSize.width];
    
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:marginSize.height];
    
    NSArray *constraints = @[width, height, right, bottom];
    [self activateConstraints:constraints];
    [self.superview addConstraints:constraints];
}

- (void)PBMAddBottomLeftConstraintsWithViewSize:(CGSize)viewSize marginSize:(CGSize)marginSize{
    if (!self.superview) {
        return;
    }
    
    self.translatesAutoresizingMaskIntoConstraints = false;
    
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:viewSize.width];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:viewSize.height];
    
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeLeft multiplier:1.0 constant:marginSize.width];
    
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:marginSize.height];
    
    NSArray *constraints = @[width, height, left, bottom];
    [self activateConstraints:constraints];
    [self.superview addConstraints:constraints];
}

- (void)PBMAddTopRightConstraintsWithViewSize:(CGSize)viewSize marginSize:(CGSize)marginSize {
    if (!self.superview) {
        return;
    }
    
    self.translatesAutoresizingMaskIntoConstraints = false;

    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:viewSize.width];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:viewSize.height];
    
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeRight multiplier:1.0 constant:marginSize.width];
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:marginSize.height];
    
    NSArray *constraints = @[width, height, right, top];
    [self activateConstraints:constraints];
    [self.superview addConstraints:constraints];
}

- (void)PBMAddTopLeftConstraintsWithViewSize:(CGSize)viewSize marginSize:(CGSize)marginSize {
    if (!self.superview) {
        return;
    }
    
    self.translatesAutoresizingMaskIntoConstraints = false;
    
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:viewSize.width];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:viewSize.height];
    
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeLeft multiplier:1.0 constant:marginSize.width];
    
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:marginSize.height];
    
    NSArray * constraints = @[width, height, left, top];
    [self activateConstraints:constraints];
    [self.superview addConstraints:constraints];
}
- (void)LogViewHierarchy {
    PBMLogInfo(@"**********LOGGING VIEW HIERARCHY**********");
    [self logViewHierarchyForView:self depth:0];
}

#pragma mark - Internal Methods

- (void)logViewHierarchyForView:(UIView *)view depth:(NSInteger) depth {
    NSString *prefix = [NSString new];
    for (int i = 0; i < depth; ++i) {
        prefix = [prefix stringByAppendingString:@"-"];
    }
    
    PBMLogInfo(@"%@view = %@ view.constraints: %@", prefix, view, view.constraints);
    
    for (UIView *subview in view.subviews) {
        [self logViewHierarchyForView:subview depth:(depth + 1)];
    }
}

- (void)activateConstraints: (NSArray*)constraints {
    for (id item in constraints) {
        NSLayoutConstraint *constraint = (NSLayoutConstraint *)item;
        [constraint setActive:YES];
    }
}

- (BOOL)pbmIsVisibleInView:(UIView *)inView {
    return self.viewExposure.exposureFactor > 0;
}

@end
