//
//  TSStackView.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 04/12/2013.
//  Copyright (c) 2013 Thesaurus Software Limited. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_OPTIONS(NSUInteger, TSIntrinsicContentSize) {
    TSIntrinsicContentSizeNone = 0 << 0,
    TSIntrinsicContentSizeWidth = 1 << 0,
    TSIntrinsicContentSizeHeight = 1 << 1,
};

@interface TSStackView : NSStackView

/*
 
 TSStackView works by observing NSView -hidden and swapping out hidden views.
 NSStackView calls -fittingSize to determine the minimum size of its subviews.
 If a view's width or height is not constrained to a value (say the right or bottom
 spacing to the superview is missing) then the fitting size will be 0 in that dimension
 and the view will not be displayed.
 
 Given the above, other approaches to obtaining the same behaviour could therefore include:
 
 1. Add and remove internal constraints to cause the fittingSize for views to collapse.
 2. Add and remove additional external zero dimension constraints to override the internal constraints.
 
 */
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


/*!
 
 Scroll view container with constraints to match the stackview width to the scrollview width.
 
 */
@property (strong, nonatomic, readonly) NSScrollView *scrollViewContainer;

/*!
 
 Set options to determine whether view reports an intrinsic content size.
 
 */
@property (assign, nonatomic) TSIntrinsicContentSize intrinsicContentSizeOptions;

/*!
 
 Background fill color.
 
 */
@property (strong, nonatomic) NSColor *backgroundColor;

@end
