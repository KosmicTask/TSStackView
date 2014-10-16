//
//  TSTextView.m
//  StackView Demo
//
//  Created by Jonathan Mitchell on 16/10/2014.
//  Copyright (c) 2014 Thesaurus Software. All rights reserved.
//

#import "TSTextView.h"

@implementation TSTextView

- (NSSize)intrinsicContentSize
{
    NSTextContainer* textContainer = [self textContainer];
    NSLayoutManager* layoutManager = [self layoutManager];
    [layoutManager ensureLayoutForTextContainer: textContainer];
    NSSize size = [layoutManager usedRectForTextContainer: textContainer].size;
    return size; 
}

- (void) didChangeText {
    [super didChangeText];
    [self invalidateIntrinsicContentSize];
}

@end
