TSStackView
============

`TSStackView` is an `NSStackView` subclass that observes the `-hidden` property of its subviews to determine if a given subview should be included in the stack layout. 

The subclass retains all views passed to `setViews:inGravity` and performs layout as required when subview visibility changes are observed. This behaviour mimics the behaviour of the WPF `StackPanel`.

The `-embedInScrollView` method can be used to embed the stack in a `NSScrollView` instance.

Usage
=====

	- (void)awakeFromNib
	{
		// add subviews
   		[self.stackView setViews:@[self.headerView] inGravity:NSStackViewGravityTop];
    	[self.stackView setViews:@[self.childView1, self.childView2, self.childView3] inGravity:NSStackViewGravityCenter];
    
    	// we want our views arranged from top to bottom
    	self.stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
    
    	// the internal views should be aligned with their centers
    	self.stackView.alignment = NSLayoutAttributeCenterX;
    
    	self.stackView.spacing = 0; // No spacing between the views
    
    	// have the stackView strongly hug the sides of the views it contains
    	[self.stackView setHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    	// have the stackView grow and shrink as its internal views grow, are added, or are removed
    	[self.stackView setHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationVertical];
    
		// toggle subview view hidden property
    	[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(foo) userInfo:nil repeats:YES];

		// wrap the stack in a scroll view and ...
		NSScrollView *scrollView = [stackView embedInScrollView];
	}

	- (void)foo
	{
		// Suspending layout only of benefit when mutating several subviews
    	[self.stackView suspendAutoLayoutWhenSubviewVisibilityChanges];
    	self.childView1.hidden = !self.childView1.isHidden;
    	self.childView2.hidden = !self.childView2.isHidden;
    	[self.stackView resumeAutoLayoutWhenSubviewVisibilityChanges];
	}

Build requirements
==================

OS X 10.9 64bit ARC

Licence
=======

MIT
