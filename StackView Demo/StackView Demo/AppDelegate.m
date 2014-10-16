//
//  AppDelegate.m
//  StackView Demo
//
//  Created by Jonathan Mitchell on 16/10/2014.
//  Copyright (c) 2014 Thesaurus Software. All rights reserved.
//

#import "AppDelegate.h"
#import "TSStackView.h"
#import "TSTextView.h"
#import "TSViewController.h"

@interface AppDelegate()

@property (weak) IBOutlet NSView *contentView;
@property (strong) TSViewController *viewController1;
@property (strong) TSViewController *viewController2;
@property (strong) TSViewController *viewController3;
@property (strong) TSStackView *stackView;
@property (strong) NSScrollView *scrollView;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.viewController1 = [TSViewController new];
    self.viewController2 = [TSViewController new];
    self.viewController3 = [TSViewController new];
    
    self.stackView = [TSStackView stackViewWithViews:@[self.viewController1.view,
                                                       self.viewController1.auxiliaryView,
                                                       self.viewController2.view,
                                                       self.viewController2.auxiliaryView,
                                                       self.viewController3.view,
                                                       self.viewController3.auxiliaryView]];
    self.stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.stackView.alignment = NSLayoutAttributeWidth;
    
    self.scrollView = [self.stackView scrollViewContainer];
    self.scrollView.drawsBackground = NO;
    
    [self addSubview:self.scrollView edgeInsets:NSEdgeInsetsMake(0, 0, 0, 0)];
}

 - (void)addSubview:(NSView *)subview edgeInsets:(NSEdgeInsets)edgeInsets
{
    // this is crucial
    [subview setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // add the subview
    [self.contentView addSubview:subview];
    
    // add constraints
    NSDictionary *views = NSDictionaryOfVariableBindings(subview);
    NSDictionary *metrics = @{@"top" : @(edgeInsets.top),
                              @"right" : @(edgeInsets.right),
                              @"bottom" : @(edgeInsets.bottom),
                              @"left" : @(edgeInsets.left),
                              };
    
    // in complex hierarchies it REALLY pays off to always
    // configure at least one constraint with a lower priority.
    // this can save lots of headaches with constraint violation exceptions
    
    // if an inexplicable constraint violation occurs then the solution is generally:
    // 1. to decrease an equality constraint priority somewhere
    // 2. to change an equality constraint into a less than or equality constaint.
    
    // NOTE: the lower priorty constraint here cured a lot of problems when loading views.
    
    // snap to left and right border
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[subview]-(right@990)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    
    // snap to top and bottom border
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[subview]-(bottom@990)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    
}

@end
