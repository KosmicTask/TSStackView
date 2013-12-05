//
//  TSStackView.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 04/12/2013.
//  Copyright (c) 2013 Thesaurus Software Limited. All rights reserved.
//

#import "TSStackView.h"

char BPContextHidden;

@interface TSStackView ()
@property (strong) NSMutableDictionary *observedViews;
@property BOOL doLayout;
@end

@implementation TSStackView

#pragma mark -
#pragma mark Setup

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _observedViews = [NSMutableDictionary new];
    _doLayout = YES;
}

#pragma mark -
#pragma mark Teardown

- (void)dealloc
{
    [self removeViewObservations:self.observedViews[@(NSStackViewGravityTop)]];
    [self removeViewObservations:self.observedViews[@(NSStackViewGravityCenter)]];
    [self removeViewObservations:self.observedViews[@(NSStackViewGravityBottom)]];
}

#pragma mark -
#pragma mark Views

- (void)setViews:(NSArray *)views inGravity:(NSStackViewGravity)gravity
{
    [self setObservedViews:views inGravity:gravity];
    [self setVisibleViews:views inGravity:gravity];
}

#pragma mark -
#pragma mark Visible views

- (void)setVisibleViews:(NSArray *)views inGravity:(NSStackViewGravity)gravity
{
    // Extract the visible items
    NSMutableArray *visibleViews = [NSMutableArray arrayWithCapacity:[views count]];
    for (NSView *view in views) {
        if (!view.isHidden) [visibleViews addObject:view];
    }
    [super setViews:visibleViews inGravity:gravity];
}

#pragma mark -
#pragma mark Observed views

- (void)setObservedViews:(NSArray *)views inGravity:(NSStackViewGravity)gravity
{
    [self removeViewObservations:[self observedViewsInGravity:gravity]];
    
    self.observedViews[@(gravity)] = views;
    
    [self addViewObservations:[self observedViewsInGravity:gravity]];
}

- (NSArray *)observedViewsInGravity:(NSStackViewGravity)gravity
{
    return self.observedViews[@(gravity)];
}

#pragma mark -
#pragma mark Visibility

- (void)hideViewsInGravity:(NSStackViewGravity)gravity
{
    [self hideViews:[self viewsInGravity:gravity]];
}

- (void)showViewsInGravity:(NSStackViewGravity)gravity
{
    [self showViews:[self viewsInGravity:gravity]];
}

- (void)showViews:(NSArray *)views
{
    for (NSView *view in views) view.hidden = YES;
}

- (void)hideViews:(NSArray *)views
{
    for (NSView *view in views) view.hidden = YES;
}

#pragma mark -
#pragma mark Gravity

- (NSStackViewGravity)gravityForObservedView:(NSView *)view
{
    for (NSStackViewGravity gravity = NSStackViewGravityTop; gravity <= NSStackViewGravityBottom; gravity++) {
        if ([[self observedViewsInGravity:gravity] containsObject:view]) return gravity;
    }
    return NSNotFound;
}

- (NSStackViewGravity)gravityForView:(NSView *)view
{
    for (NSStackViewGravity gravity = NSStackViewGravityTop; gravity <= NSStackViewGravityBottom; gravity++) {
        if ([[self viewsInGravity:gravity] containsObject:view]) return gravity;
    }
    return NSNotFound;
}

#pragma mark -
#pragma mark KVO

- (void)addViewObservations:(NSArray *)views
{
    for (NSView *view in views) {
        [view addObserver:self forKeyPath:@"hidden" options:nil context:&BPContextHidden];
    }
}

- (void)removeViewObservations:(NSArray *)views
{
    for (NSView *view in views) {
        [view removeObserver:self forKeyPath:@"hidden"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &BPContextHidden) {
        
        if (self.doLayout) {
            NSView *view = (NSView *)object;
            NSAssert([view isKindOfClass:[NSView class]], @"NSView expected");
            
            // get the gravity for the observed view
            NSStackViewGravity gravity = [self gravityForObservedView:view];
            
            // show all visible views in the gravity
            [self setVisibleViews:[self observedViewsInGravity:gravity] inGravity:gravity];
        }
    }
}

#pragma mark -
#pragma mark AutoLayout

- (void)suspendAutoLayoutWhenSubviewVisibilityChanges
{
    self.doLayout = NO;
}

- (void)resumeAutoLayoutWhenSubviewVisibilityChanges
{
    self.doLayout = YES;
    for (NSStackViewGravity gravity = NSStackViewGravityTop; gravity <= NSStackViewGravityBottom; gravity++) {
        [self setVisibleViews:[self observedViewsInGravity:gravity] inGravity:gravity];
    }
}

@end
