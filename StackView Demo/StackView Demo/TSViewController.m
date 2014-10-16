//
//  TSViewController.m
//  StackView Demo
//
//  Created by Jonathan Mitchell on 16/10/2014.
//  Copyright (c) 2014 Thesaurus Software. All rights reserved.
//

#import "TSViewController.h"

@interface TSViewController ()
- (IBAction)toggleView:(id)sender;
@end

@implementation TSViewController

- (id)init
{
    return [self initWithNibName:[self className] bundle:nil];
}

- (IBAction)toggleView:(id)sender
{
    self.view.hidden = ![self.view isHidden];
}
@end
