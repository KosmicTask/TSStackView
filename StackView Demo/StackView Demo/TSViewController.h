//
//  TSViewController.h
//  StackView Demo
//
//  Created by Jonathan Mitchell on 16/10/2014.
//  Copyright (c) 2014 Thesaurus Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TSTextView.h"

@interface TSViewController : NSViewController

@property (strong) IBOutlet TSTextView *textView;
@property (strong) IBOutlet NSView *auxiliaryView;
@end
