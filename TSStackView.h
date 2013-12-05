//
//  TSStackView.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 04/12/2013.
//  Copyright (c) 2013 Thesaurus Software Limited. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSStackView : NSStackView


/*!
 
 Suspend auto layout triggered by change in subview visibility.
 
 Auto layout may be suspended to improve performance when modiftying the visbility of a number of subviews.
 
 Must be matched with a call to -resumeAutoLayoutWhenSubviewVisibilityChanges
 
 */
- (void)suspendAutoLayoutWhenSubviewVisibilityChanges;

/*!
 
 Resume auto layout triggered by change in subview visibility.
 
 */
- (void)resumeAutoLayoutWhenSubviewVisibilityChanges;

/*!
 
 Hide all views in gravity
 
 */
- (void)hideViewsInGravity:(NSStackViewGravity)gravity;

/*!
 
 Show all views in gravity
 
 */
- (void)showViewsInGravity:(NSStackViewGravity)gravity;
@end
