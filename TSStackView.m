//
//  TSStackView.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 04/12/2013.
//  Copyright (c) 2013 Thesaurus Software Limited. All rights reserved.
//
#import "TSStackView.h"
#import "TSClipView.h"

#define TS_LOG_SUBTREE
#undef TS_LOG_SUBTREE   // comment this to log the subtree

@interface NSView (TSStackView)
+ (void)ts_disableTranslatesAutoresizingMaskIntoConstraints:(NSArray *)views;
- (void)ts_disableTranslatesAutoresizingMaskIntoConstraints:(NSArray *)views;
@end

char BPContextHidden;

@interface TSStackView ()
@property (strong) NSMutableDictionary *observedViews;
@property BOOL doLayout;
@property (strong) NSArray *stackViewConstraints;
@property (strong, nonatomic, readwrite) NSScrollView *scrollViewContainer;
@end

@implementation TSStackView

#pragma mark -
#pragma mark Factory

+ (id) stackViewWithViews:(NSArray *)views
{
    // the super call guarantees that self.translatesAutoresizingMaskIntoConstraints == NO
    [self ts_disableTranslatesAutoresizingMaskIntoConstraints:views];
    NSStackView *stackView = [super stackViewWithViews:views];
    return stackView;
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
#pragma mark Visible views

- (void)setVisibleViews:(NSArray *)views inGravity:(NSStackViewGravity)gravity
{
    // Extract the visible items
    NSMutableArray *visibleViews = [NSMutableArray arrayWithCapacity:[views count]];
    for (NSView *view in views) {
        if (!view.isHidden) [visibleViews addObject:view];
    }
    [super setViews:visibleViews inGravity:gravity];
    
    [self invalidateIntrinsicContentSize];
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

- (void)addViewObservation:(NSView *)view
{
    [view addObserver:self forKeyPath:@"hidden" options:nil context:&BPContextHidden];
}

- (void)addViewObservations:(NSArray *)views
{
    for (NSView *view in views) {
        [self addViewObservation:view];
    }
}

- (void)removeViewObservation:(NSView *)view
{
    [view removeObserver:self forKeyPath:@"hidden"];
}

- (void)removeViewObservations:(NSArray *)views
{
    for (NSView *view in views) {
        [self removeViewObservation:view];
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

- (NSSize)intrinsicContentSize
{
    CGFloat intrinsicWidth = NSViewNoInstrinsicMetric;
    CGFloat intrinsicHeight = NSViewNoInstrinsicMetric;
    
    // This method makes assumptions about how the internal views are laid out.
    // The assumptions are reasonable based on the published geometry for NSStackView.
    // However, future changes to NSStackView may cause this method to misbehave.
    
    // calculate intrinsic content height.
    if (self.intrinsicContentSizeOptions & TSIntrinsicContentSizeHeight) {
        intrinsicHeight = 0;
        intrinsicHeight += (self.edgeInsets.top + self.edgeInsets.bottom);  // inset
        
        for (NSView *view in self.views) {
            intrinsicHeight += view.frame.size.height;
            
            // spacing
            if (view != self.views.lastObject) {
                CGFloat viewSpacing = [self customSpacingAfterView:view];
                if (viewSpacing == NSStackViewSpacingUseDefault) {
                    viewSpacing = self.spacing;
                }
                intrinsicHeight += viewSpacing;
            }
        }
    }

    // calculate intrinsic content width
    if (self.intrinsicContentSizeOptions & TSIntrinsicContentSizeWidth) {
        intrinsicWidth = 0;
        intrinsicWidth += (self.edgeInsets.left + self.edgeInsets.right);   // inset
        
        for (NSView *view in self.views) {
            intrinsicWidth += view.frame.size.width;
            
            // spacing
            if (view != self.views.lastObject) {
                CGFloat viewSpacing = [self customSpacingAfterView:view];
                if (viewSpacing == NSStackViewSpacingUseDefault) {
                    viewSpacing = self.spacing;
                }
                intrinsicWidth += viewSpacing;
            }
        }
    }

#ifdef TS_LOG_SUBTREE
    if (self.intrinsicContentSizeOptions != TSIntrinsicContentSizeNone) {
        NSLog(@"%@ _subtreeDescription = %@", self, [self performSelector:@selector(_subtreeDescription)]);
    }
#endif
    
    return NSMakeSize(intrinsicWidth, intrinsicHeight);
}

- (void)setIntrinsicContentSizeOptions:(TSIntrinsicContentSize)intrinsicSizeOptions
{
    _intrinsicContentSizeOptions = intrinsicSizeOptions;
    [self invalidateIntrinsicContentSize];
}

#pragma mark -
#pragma mark Adding and removing views

- (void)setViews:(NSArray *)views inGravity:(NSStackViewGravity)gravity
{
    [self ts_disableTranslatesAutoresizingMaskIntoConstraints:views];
    [self setObservedViews:views inGravity:gravity];
    [self setVisibleViews:views inGravity:gravity];
    
    [self invalidateIntrinsicContentSize];
}

- (void)addView:(NSView *)aView inGravity:(NSStackViewGravity)gravity
{
    if (!aView.isHidden) {
        [super addView:aView inGravity:gravity];
    }
    
    [self.observedViews[@(gravity)] addObject:aView];
    [self addViewObservation:aView];
    
    [self invalidateIntrinsicContentSize];
}

- (void)insertView:(NSView *)aView atIndex:(NSUInteger)index inGravity:(NSStackViewGravity)gravity
{
    if (!aView.isHidden) {
        [super insertView:aView atIndex:index inGravity:gravity];
    }
    
    [self.observedViews[@(gravity)] addObject:aView];
    [self addViewObservation:aView];

    [self invalidateIntrinsicContentSize];
}

- (void)removeView:(NSView *)aView
{
    for (NSUInteger gravity = NSStackViewGravityTop; gravity <= NSStackViewGravityBottom; gravity++) {
        if ([[self viewsInGravity:gravity] containsObject:aView]) {
            [super removeView:aView];
            [self removeViewObservation:aView];
            [self.observedViews[@(gravity)] removeObject:aView];
        }
    }
    
    [self invalidateIntrinsicContentSize];
}

#pragma mark -
#pragma mark Embedding
- (NSScrollView *)scrollViewContainer
{
    if (!_scrollViewContainer) {
        
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
        
        self.scrollViewContainer = scrollView;
    }
    return _scrollViewContainer;
}

#pragma mark -
#pragma mark drawing

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    [self needsDisplay];
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (self.backgroundColor) {
        [[NSColor whiteColor] set];
        NSRectFill(dirtyRect);
    } else {
        [super drawRect:dirtyRect];
    }
}

@end

@implementation NSView (TSStackView)

+ (void)ts_disableTranslatesAutoresizingMaskIntoConstraints:(NSArray *)views
{
    for (NSView *view in views) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
    }
}

- (void)ts_disableTranslatesAutoresizingMaskIntoConstraints:(NSArray *)views
{
    [[self class] ts_disableTranslatesAutoresizingMaskIntoConstraints:views];
}
@end
