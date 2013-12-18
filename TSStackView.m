//
//  TSStackView.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 04/12/2013.
//  Copyright (c) 2013 Thesaurus Software Limited. All rights reserved.
//

#import "TSStackView.h"
#import "TSClipView.h"

@interface NSView (TSStackView)
+ (void)ts_disableTranslatesAutoresizingMaskIntoConstraints:(NSArray *)views;
- (void)ts_disableTranslatesAutoresizingMaskIntoConstraints:(NSArray *)views;
@end

char BPContextHidden;

@interface TSStackView ()
@property (strong) NSMutableDictionary *observedViews;
@property BOOL doLayout;
@property (strong) NSArray *stackViewConstraints;

@end

@implementation TSStackView

#pragma mark -
#pragma mark Factory

+ (id) stackViewWithViews:(NSArray *)views
{
    [self ts_disableTranslatesAutoresizingMaskIntoConstraints:views];
    return [super stackViewWithViews:views];
}

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
    [self ts_disableTranslatesAutoresizingMaskIntoConstraints:views];
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


#pragma mark -
#pragma mark Embedding

- (NSScrollView *)embedInScrollView
{
    // allocate scroll view
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;

    // allocate flipped clip view
    TSClipView *clipView = [[TSClipView alloc] initWithFrame:scrollView.contentView.frame];
    scrollView.contentView = clipView;
    NSAssert(scrollView.contentView.isFlipped, @"ScrollView contenView must be flipped? Use TSClipView");
    
    // configure the scrollview
    scrollView.borderType = NSNoBorder;
    scrollView.hasHorizontalScroller = YES;
    scrollView.hasVerticalScroller = YES;
    scrollView.autohidesScrollers = YES;
    
    // stackview is the document
    scrollView.documentView = self;
    
    // constrain stackview to match dimension of scrollview
    NSDictionary *viewsDict = NSDictionaryOfVariableBindings(self);
    NSString *vfl = nil;
    if (self.orientation == NSUserInterfaceLayoutOrientationVertical) {
        vfl = @"H:|-0-[self]-0-|";
    } else {
        vfl = @"V:|-0-[self]-0-|";
    }
    self.stackViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:vfl options:0 metrics:nil views:viewsDict];
    
    [scrollView addConstraints:self.stackViewConstraints];
    
    return scrollView;
}
@end

@implementation NSView (TSStackView)

+ (void)ts_disableTranslatesAutoresizingMaskIntoConstraints:(NSArray *)views
{
    for (NSView *view in views) {
        view.translatesAutoresizingMaskIntoConstraints = NO;;
    }
}

- (void)ts_disableTranslatesAutoresizingMaskIntoConstraints:(NSArray *)views
{
    [[self class] ts_disableTranslatesAutoresizingMaskIntoConstraints:views];
}
@end
