//
//  DCIntrospect.m
//
//  Created by Domestic Cat on 29/04/11.
//

#import "DCIntrospect.h"

DCIntrospect *sharedInstance = nil;

@implementation DCIntrospect
@synthesize keyboardBindingsOn, showStatusBarOverlay, gestureRecognizer;
@synthesize on;
@synthesize viewOutlines, highlightOpaqueViews, flashOnRedraw;
@synthesize statusBarOverlay;
@synthesize inputField;
@synthesize toolbar;
@synthesize frameView;
@synthesize objectNames;
@synthesize blockActions, waitingForBlockKey;
@synthesize currentView, originalFrame, originalAlpha;
@synthesize showingHelp;

#pragma mark Setup

+ (DCIntrospect *)sharedIntrospector
{
#ifdef DEBUG
	if (!sharedInstance)
	{
		sharedInstance = [[DCIntrospect alloc] init];
		sharedInstance.keyboardBindingsOn = YES;
		sharedInstance.showStatusBarOverlay = YES;
	}
#endif
	return sharedInstance;
}

- (void)setup
{
	UIWindow *mainWindow = [self mainWindow];
	if (!mainWindow)
	{
		NSLog(@"DCIntrospect: Couldn't setup.  No main window?");
		return;
	}

	if (!self.statusBarOverlay)
	{
		self.statusBarOverlay = [[[DCStatusBarOverlay alloc] init] autorelease];
	}

	if (!self.inputField)
	{
		self.inputField = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
		self.inputField.delegate = self;
		self.inputField.autocorrectionType = UITextAutocorrectionTypeNo;
		self.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.inputField.inputView = [[[UIView alloc] init] autorelease];
		[mainWindow addSubview:self.inputField];
	}

	if (self.keyboardBindingsOn)
	{
		if (![self.inputField becomeFirstResponder])
		{
			[self performSelector:@selector(takeFirstResponder) withObject:nil afterDelay:0.5];
		}
	}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarTapped) name:kDCIntrospectNotificationStatusBarTapped object:nil];

	// reclaim the keyboard if it is taken
	[[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification
													  object:nil
													   queue:nil
												  usingBlock:^(NSNotification *notification) {
													  // needs to be done after a delay or else it doesn't work.
													  if (self.keyboardBindingsOn)
														  [self.inputField performSelector:@selector(becomeFirstResponder)
																				withObject:nil
																				afterDelay:0.1];
												  }];

	// listen for device orientation changes to adjust the status bar
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)takeFirstResponder
{
	if (![self.inputField becomeFirstResponder])
		NSLog(@"DCIntrospect: Couldn't initiate keyboard field.  Is the keyboard used elsewhere?");
}

#pragma mark Custom Setters

- (void)setGestureRecognizer:(UIGestureRecognizer *)newGestureRecognizer
{
	UIWindow *mainWindow = [self mainWindow];
	[mainWindow removeGestureRecognizer:gestureRecognizer];

	[gestureRecognizer release];
	gestureRecognizer = nil;
	gestureRecognizer = [newGestureRecognizer retain];
	[gestureRecognizer addTarget:self action:@selector(invokeIntrospector)];
	[mainWindow addGestureRecognizer:newGestureRecognizer];
}

- (void)setKeyboardBindingsOn:(BOOL)newKeyboardBindingsOn
{
	keyboardBindingsOn = newKeyboardBindingsOn;
	if (self.keyboardBindingsOn)
		[self.inputField becomeFirstResponder];
	else
		[self.inputField resignFirstResponder];
}

#pragma mark Main Actions

- (void)invokeIntrospector
{
	self.on = !self.on;

	if (self.on)
	{
		[self updateViews];
		[self updateStatusBar];
		[self updateFrameView];

		if (keyboardBindingsOn)
			[self.inputField becomeFirstResponder];
		else
			[self.inputField resignFirstResponder];

		[[NSNotificationCenter defaultCenter] postNotificationName:kDCIntrospectNotificationIntrospectionDidStart
															object:nil];
	}
	else
	{
		self.toolbar.alpha = 0;
		if (self.viewOutlines)
			[self toggleOutlines];
		if (self.highlightOpaqueViews)
			[self toggleOpaqueViews];
		if (self.showingHelp)
			[self toggleHelp];
	
		self.statusBarOverlay.hidden = YES;
		self.frameView.alpha = 0;
		self.currentView = nil;
		self.waitingForBlockKey = NO;

		[[NSNotificationCenter defaultCenter] postNotificationName:kDCIntrospectNotificationIntrospectionDidEnd
															object:nil];
	}
}

- (void)touchAtPoint:(CGPoint)point
{
	NSMutableArray *views = [NSMutableArray array];
	CGPoint newTouchPoint = point;
	newTouchPoint = [[self mainWindow] convertPoint:newTouchPoint fromView:self.frameView];
	[views addObjectsFromArray:[self viewsAtPoint:newTouchPoint inView:[self mainWindow]]];
	if (views.count == 0)
		return;

	UIView *newView = [views lastObject];
	if (newView != self.currentView)
	{
		if (self.frameView.rectsToOutline.count > 0)
		{
			[self.frameView.rectsToOutline removeAllObjects];
			[self.frameView setNeedsDisplay];
			self.viewOutlines = NO;
		}

		self.currentView = [views lastObject];
		self.originalFrame = self.currentView.frame;
		self.originalAlpha = self.currentView.alpha;
		[self updateFrameView];
		[self updateStatusBar];
		[self updateToolbar];
	}
}

- (void)statusBarTapped
{
	if (self.showingHelp)
	{
		[self toggleHelp];
		return;
	}

	UIWindow *mainWindow = [self mainWindow];

	// if a view is selected, show the toolbar, otherwise show help
	if (self.currentView)
	{
		if (!self.toolbar)
		{
			CGRect rect = CGRectMake(0.0, [UIApplication sharedApplication].statusBarFrame.size.height, mainWindow.frame.size.width, 30.0);
			self.toolbar = [[[UIScrollView alloc] initWithFrame:rect] autorelease];
			self.toolbar.backgroundColor = [UIColor blackColor];
			self.toolbar.alpha = 0.0;
			[mainWindow addSubview:self.toolbar];

			[self updateViews];
		}

		[self updateToolbar];

		if (self.toolbar.alpha == 1)
		{
			[self fadeView:self.toolbar toAlpha:0.0];
		}
		else
		{
			[mainWindow bringSubviewToFront:self.toolbar];
			[self fadeView:self.toolbar toAlpha:1.0];
		}
	}
}

#pragma mark Keyboard Capture

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if (self.showingHelp)
	{
		[self toggleHelp];
		return NO;
	}

	if ([string isEqualToString:kDCIntrospectKeysInvoke])
	{
		[self invokeIntrospector];
		return NO;
	}

	if (!self.on)
		return NO;

	if (self.waitingForBlockKey)
	{
		self.waitingForBlockKey = NO;

		NSDictionary *blockAction = [self blockForKeyBinding:string];
		NSString *statusString = nil;
		if (blockAction)
		{
			statusString = [NSString stringWithFormat:@"Running block: %@", [blockAction objectForKey:@"name"]];
			Block block = [blockAction objectForKey:@"block"];
			block();
		}
		else
		{
			statusString = [NSString stringWithFormat:@"No block for key binding %@", string];
		}

		if (self.showStatusBarOverlay)
			[self showTemporaryStringInStatusBar:statusString];
		else
			NSLog(@"%@", statusString);

		return NO;
	}

	if ([string isEqualToString:kDCIntrospectKeysEnterBlockMode])
	{
		self.waitingForBlockKey = YES;
		[self enterBlockMode];
		return NO;
	}

	if ([string isEqualToString:kDCIntrospectKeysToggleViewOutlines])
	{
		[self toggleOutlines];
		return NO;
	}
	else if ([string isEqualToString:kDCIntrospectKeysToggleNonOpaqueViews])
	{
		[self toggleOpaqueViews];
		return NO;
	}
	else if ([string isEqualToString:kDCIntrospectKeysToggleFlashViewRedraws])
	{
		[self toggleRedrawFlashing];
		return NO;
	}
	else if ([string isEqualToString:kDCIntrospectKeysToggleShowCoordinates])
	{
		[UIView animateWithDuration:0.15
							  delay:0
							options:UIViewAnimationOptionAllowUserInteraction
						 animations:^{
							 self.frameView.touchPointLabel.alpha = !self.frameView.touchPointLabel.alpha;
						 } completion:^(BOOL finished) {
							 NSString *string = [NSString stringWithFormat:@"Coordinates are %@", (self.frameView.touchPointLabel.alpha) ? @"on" : @"off"];
							 if (self.showStatusBarOverlay)
								 [self showTemporaryStringInStatusBar:string];
							 else
								 NSLog(@"%@", string);
						 }];
		return NO;
	}
	else if ([string isEqualToString:kDCIntrospectKeysToggleHelp])
	{
		[self toggleHelp];
		return NO;
	}

	if (self.on && self.currentView)
	{
		if ([string isEqualToString:kDCIntrospectKeysLogProperties])
		{
			[self logPropertiesForObject:self.currentView];
			return NO;
		}
		else if ([string isEqualToString:kDCIntrospectKeysLogViewRecursive])
		{
			[self logRecursiveDescriptionForView:self.currentView];
			return NO;
		}
		else if ([string isEqualToString:kDCIntrospectKeysSetNeedsDisplay])
		{
			[self forceSetNeedsDisplay];
			return NO;
		}
		else if ([string isEqualToString:kDCIntrospectKeysSetNeedsLayout])
		{
			[self forceSetNeedsLayout];
			return NO;
		}
		else if ([string isEqualToString:kDCIntrospectKeysReloadData])
		{
			[self forceReloadOfView];
			return NO;
		}

		if ([string isEqualToString:kDCIntrospectKeysSelectMoveUpViewHeirachy])
		{
			if (self.currentView.superview)
			{
				self.currentView = self.currentView.superview;
				[self updateFrameView];
				[self updateStatusBar];
				[self updateToolbar];
			}
			return NO;
		}

		CGRect frame = self.currentView.frame;
		if ([string isEqualToString:kDCIntrospectKeysNudgeViewLeft])
			frame.origin.x -= 1.0;
		else if ([string isEqualToString:kDCIntrospectKeysNudgeViewRight])
			frame.origin.x += 1.0;
		else if ([string isEqualToString:kDCIntrospectKeysNudgeViewUp])
			frame.origin.y -= 1.0;
		else if ([string isEqualToString:kDCIntrospectKeysNudgeViewDown])
			frame.origin.y += 1.0;
		else if ([string isEqualToString:kDCIntrospectKeysCenterInSuperview])
			frame = CGRectMake(floorf((self.currentView.superview.frame.size.width - frame.size.width) / 2.0),
							   floorf((self.currentView.superview.frame.size.height - frame.size.height) / 2.0),
							   frame.size.width,
							   frame.size.height);
		else if ([string isEqualToString:kDCIntrospectKeysIncreaseWidth])
			frame.size.width += 1.0;
		else if ([string isEqualToString:kDCIntrospectKeysDecreaseWidth])
			frame.size.width -= 1.0;
		else if ([string isEqualToString:kDCIntrospectKeysIncreaseHeight])
			frame.size.height += 1.0;
		else if ([string isEqualToString:kDCIntrospectKeysDecreaseHeight])
			frame.size.height -= 1.0;
		else if ([string isEqualToString:kDCIntrospectKeysIncreaseViewAlpha])
			self.currentView.alpha += 0.05;
		else if ([string isEqualToString:kDCIntrospectKeysDecreaseViewAlpha])
			self.currentView.alpha -= 0.05;

		self.currentView.frame = CGRectMake(floorf(frame.origin.x),
											floorf(frame.origin.y),
											floorf(frame.size.width),
											floorf(frame.size.height));

		[self updateFrameView];
		[self updateStatusBar];
	}

	return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (!self.currentView)
		return YES;

	NSString *varName = [self nameForObject:self.currentView];
	if ([varName isEqualToString:[NSString stringWithFormat:@"%@", self.currentView.class]])
		varName = @"<#view#>";

	NSMutableString *outputString = [NSMutableString string];
	if (!CGRectEqualToRect(self.originalFrame, self.currentView.frame))
	{
		[outputString appendFormat:@"%@.frame = CGRectMake(%.0f, %.0f, %.0f, %.0f);\n", varName, self.currentView.frame.origin.x, self.currentView.frame.origin.y, self.currentView.frame.size.width, self.currentView.frame.size.height];
	}

	if (self.originalAlpha != self.currentView.alpha)
	{
		[outputString appendFormat:@"%@.alpha = %.2f;\n", varName, self.currentView.alpha];
	}

	if (outputString.length == 0)
		NSLog(@"DCIntrospect: No changes made to %@.", self.currentView.class);
	else
		printf("\n\n%s\n", [outputString UTF8String]);

	return YES;
}


#pragma mark Object Names

- (void)setName:(NSString *)name forObject:(id)object accessDirectly:(BOOL)accessDirectly
{
	if (!self.objectNames)
		self.objectNames = [NSMutableDictionary dictionary];

	if (accessDirectly)
		name = [@"self." stringByAppendingString:name];

	[self.objectNames setValue:object forKey:name];
}

- (NSString *)nameForObject:(id)object
{
	__block NSString *objectName = [NSString stringWithFormat:@"%@", [object class]];
	if (!self.objectNames)
		return objectName;

	[self.objectNames enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if (obj == object)
		{
			objectName = (NSString *)key;
			*stop = YES;
		}
	}];

	return objectName;
}

- (void)removeNamesForViewsInView:(UIView *)view
{
	if (!self.objectNames)
		return;

	NSMutableArray *objectsToRemove = [NSMutableArray array];
	[self.objectNames enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if ([[obj class] isSubclassOfClass:[UIView class]])
		{
			UIView *subview = (UIView *)obj;
			if ([self view:view containsSubview:subview])
				[objectsToRemove addObject:key];
		}
	}];

	[objectsToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *key = (NSString *)obj;
		[self.objectNames removeObjectForKey:key];
	}];
}

- (void)removeNameForObject:(id)object
{
	if (!self.objectNames)
		return;

	NSString *objectName = [self nameForObject:object];
	[self.objectNames removeObjectForKey:objectName];
}

#pragma mark Block Actions

- (void)addBlock:(void (^)(void))block withName:(NSString *)name keyBinding:(NSString *)keyBinding
{
	if (!self.blockActions)
		self.blockActions = [NSMutableArray array];

	NSDictionary *blockAndName = [NSDictionary dictionaryWithObjectsAndKeys:
								  [[block copy] autorelease], @"block",
								  name, @"name",
								  keyBinding, @"binding",
								  nil];
	[self.blockActions addObject:blockAndName];
}

- (void)enterBlockMode
{
	if (!self.blockActions)
	{
		self.waitingForBlockKey = NO;
		NSString *string = @"No block actions have been added.";
		if (self.showStatusBarOverlay)
			[self showTemporaryStringInStatusBar:string];
		else
			NSLog(@"%@", string);
		return;
	}

	[self updateStatusBar];

	NSMutableString *outputString = [NSMutableString stringWithString:@"** Block Actions **\n"];
	for (NSDictionary *blockAction in self.blockActions)
	{

		NSString *name = [blockAction objectForKey:@"name"];
		NSString *binding = [blockAction objectForKey:@"binding"];
		[outputString appendFormat:@"  %@: %@\n", binding, name];
	}

	[outputString appendString:@"\nWaiting for block key binding...\n\n"];
	printf("%s", [outputString UTF8String]);
}

- (NSDictionary *)blockForKeyBinding:(NSString *)keyBinding
{
	for (NSDictionary *blockAction in self.blockActions)
	{
		NSString *binding = [blockAction objectForKey:@"binding"];
		if ([binding isEqualToString:keyBinding])
		{
			return blockAction;
		}
	}

	return nil;
}

#pragma mark Layout

- (void)updateFrameView
{
	UIWindow *mainWindow = [self mainWindow];
	if (!self.frameView)
	{
		self.frameView = [[[DCFrameView alloc] initWithFrame:(CGRect){ CGPointZero, mainWindow.frame.size } delegate:self] autorelease];
		[mainWindow addSubview:self.frameView];
		self.frameView.alpha = 0.0;
		[self updateViews];
	}
	
	[mainWindow bringSubviewToFront:self.frameView];
	[mainWindow bringSubviewToFront:self.toolbar];
	
	if (self.on)
	{
		if (self.currentView)
		{
			self.frameView.mainRect = [self.currentView.superview convertRect:self.currentView.frame toView:self.frameView];
			if (self.currentView.superview == mainWindow)
				self.frameView.superRect = CGRectZero;
			else
				self.frameView.superRect = [self.currentView.superview.superview convertRect:self.currentView.superview.frame toView:self.frameView];
		}
		else
		{
			self.frameView.mainRect = CGRectZero;
		}
		
		[self fadeView:self.frameView toAlpha:1.0];
	}
	else
	{
		[self fadeView:self.frameView toAlpha:0.0];
	}
}

- (void)updateStatusBar
{
	if (self.waitingForBlockKey)
	{
		self.statusBarOverlay.leftLabel.text = @"Waiting for block key binding...";
		self.statusBarOverlay.rightLabel.text = nil;
		return;
	}

	if (self.currentView)
	{
		NSString *nameForObject = [self nameForObject:self.currentView];

		// remove the 'self.' if it's there to save space
		if ([nameForObject hasPrefix:@"self."])
			nameForObject = [nameForObject substringFromIndex:@"self.".length];
	
		if (self.currentView.tag != 0)
			self.statusBarOverlay.leftLabel.text = [NSString stringWithFormat:@"%@ (tag: %i)", nameForObject, self.currentView.tag];
		else
			self.statusBarOverlay.leftLabel.text = [NSString stringWithFormat:@"%@", nameForObject];
		
		self.statusBarOverlay.rightLabel.text = NSStringFromCGRect(self.currentView.frame);
	}
	else
	{
		self.statusBarOverlay.leftLabel.text = @"DCIntrospect";
		self.statusBarOverlay.rightLabel.text = nil;
	}
	
	if (self.showStatusBarOverlay)
		self.statusBarOverlay.hidden = NO;
	else
		self.statusBarOverlay.hidden = YES;
}

- (void)updateViews
{
	// current interface orientation
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
	CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
	CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
	CGSize toolbarSize = CGSizeMake(statusBarSize.width, 30.0);

	CGFloat pi = (CGFloat)M_PI;
	if (orientation == UIDeviceOrientationPortrait)
	{
		self.frameView.transform = CGAffineTransformIdentity;
		self.frameView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
		self.toolbar.transform = self.frameView.transform;
		self.toolbar.frame = CGRectMake(0, statusBarSize.height, self.toolbar.frame.size.width, self.toolbar.frame.size.height);
	}
	else if (orientation == UIDeviceOrientationLandscapeLeft)
	{
		self.frameView.transform = CGAffineTransformMakeRotation(pi * (90) / 180.0f);
		self.frameView.frame = CGRectMake(screenWidth - screenHeight, 0, screenHeight, screenHeight);
		self.toolbar.transform = self.frameView.transform;
		self.toolbar.frame = CGRectMake(screenWidth - statusBarSize.width - toolbarSize.height, 0, toolbarSize.height, screenHeight);
	}
	else if (orientation == UIDeviceOrientationLandscapeRight)
	{
		self.frameView.transform = CGAffineTransformMakeRotation(pi * (-90) / 180.0f);
		self.frameView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
		self.toolbar.transform = self.frameView.transform;
		self.toolbar.frame = CGRectMake(statusBarSize.width, 0, toolbarSize.height, screenHeight);
	}
	else if (orientation == UIDeviceOrientationPortraitUpsideDown)
	{
		self.frameView.transform = CGAffineTransformMakeRotation(pi);
		self.frameView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
		self.toolbar.transform = self.frameView.transform;
		self.toolbar.frame = CGRectMake(0, screenHeight - statusBarSize.height - toolbarSize.height, screenWidth, toolbarSize.height);
	}

	self.currentView = nil;
	[self updateFrameView];
}

- (void)updateToolbar
{
	// setup toolbar
	[self.toolbar.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[(UIView *)obj removeFromSuperview];
	}];

	NSMutableArray *buttons = [NSMutableArray array];
	
	UIButton *logDescriptionButton = [UIButton buttonWithType:UIButtonTypeCustom];
	NSString *title = [NSString stringWithFormat:@"log view (%@)", kDCIntrospectKeysLogViewRecursive];
	[logDescriptionButton setTitle:title forState:UIControlStateNormal];
	[logDescriptionButton addTarget:self action:@selector(logRecursiveDescriptionForCurrentView) forControlEvents:UIControlEventTouchUpInside];
	[buttons addObject:logDescriptionButton];

	UIButton *logPropertiesButton = [UIButton buttonWithType:UIButtonTypeCustom];
	title = [NSString stringWithFormat:@"log properties (%@)", kDCIntrospectKeysLogProperties];
	[logPropertiesButton setTitle:title forState:UIControlStateNormal];
	[logPropertiesButton addTarget:self action:@selector(logPropertiesForCurrentView) forControlEvents:UIControlEventTouchUpInside];
	[buttons addObject:logPropertiesButton];
	
	UIButton *forceSetNeedsDisplay = [UIButton buttonWithType:UIButtonTypeCustom];
	title = [NSString stringWithFormat:@"setNeedsDisplay (%@)", kDCIntrospectKeysSetNeedsDisplay];
	[forceSetNeedsDisplay setTitle:title forState:UIControlStateNormal];
	[forceSetNeedsDisplay addTarget:self action:@selector(forceSetNeedsDisplay) forControlEvents:UIControlEventTouchUpInside];
	[buttons addObject:forceSetNeedsDisplay];
	
	UIButton *forceSetNeedsLayout = [UIButton buttonWithType:UIButtonTypeCustom];
	title = [NSString stringWithFormat:@"setNeedsLayout (%@)", kDCIntrospectKeysSetNeedsLayout];
	[forceSetNeedsLayout setTitle:title forState:UIControlStateNormal];
	[forceSetNeedsLayout addTarget:self action:@selector(forceSetNeedsLayout) forControlEvents:UIControlEventTouchUpInside];
	[buttons addObject:forceSetNeedsLayout];

	if ([self.currentView class] == [UITableView class])
	{
		UIButton *reloadTableView = [UIButton buttonWithType:UIButtonTypeCustom];
		title = [NSString stringWithFormat:@"reloadData (%@)", kDCIntrospectKeysReloadData];
		[reloadTableView setTitle:title forState:UIControlStateNormal];
		[reloadTableView addTarget:self action:@selector(forceReloadOfView) forControlEvents:UIControlEventTouchUpInside];
		[buttons addObject:reloadTableView];
	}

	CGFloat x = 0;
	for (UIButton *button in buttons)
	{
		button.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
		button.titleLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
		[button setTitleColor:[UIColor colorWithWhite:0.78 alpha:1.0] forState:UIControlStateNormal];
		[button setTitleColor:[UIColor colorWithWhite:1.0 alpha:1.0] forState:UIControlStateHighlighted];
		CGSize titleSize = [button.titleLabel.text sizeWithFont:button.titleLabel.font];
		button.frame = CGRectMake(x, 0.0, titleSize.width + 10.0, 24.0);
		[self.toolbar addSubview:button];
		x += button.frame.size.width;
	}

	self.toolbar.contentSize = CGSizeMake(x, self.toolbar.frame.size.height);
}

- (void)showTemporaryStringInStatusBar:(NSString *)string
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateStatusBar) object:nil];

	self.statusBarOverlay.leftLabel.text = string;
	self.statusBarOverlay.rightLabel.text = nil;
	[self performSelector:@selector(updateStatusBar) withObject:nil afterDelay:0.75];
}

#pragma mark Actions

- (void)logRecursiveDescriptionForCurrentView
{
	[self logRecursiveDescriptionForView:self.currentView];
}

- (void)logRecursiveDescriptionForView:(UIView *)view
{
#ifdef DEBUG
	// [UIView recursiveDescription] is a private method.
	NSLog(@"%@", [view recursiveDescription]);
#endif
}

- (void)forceSetNeedsDisplay
{
	[self.currentView setNeedsDisplay];
}

- (void)forceSetNeedsLayout
{
	[self.currentView setNeedsLayout];
}

- (void)forceReloadOfView
{
	if ([self.currentView class] == [UITableView class])
		[(UITableView *)self.currentView reloadData];
}

- (void)toggleOutlines
{
	UIWindow *mainWindow = [self mainWindow];
	self.viewOutlines = !self.viewOutlines;

	if (self.viewOutlines)
		[self addOutlinesToFrameViewFromSubview:mainWindow];
	else
		[self.frameView.rectsToOutline removeAllObjects];

	[self.frameView setNeedsDisplay];

	NSString *string = [NSString stringWithFormat:@"Showing all view outlines is %@", (self.viewOutlines) ? @"on" : @"off"];
	if (self.showStatusBarOverlay)
		[self showTemporaryStringInStatusBar:string];
	else
		NSLog(@"%@", string);
}

- (void)addOutlinesToFrameViewFromSubview:(UIView *)view
{
	for (UIView *subview in view.subviews)
	{
		if (subview == self.toolbar || subview == self.frameView)
			continue;
		
		CGRect rect = [subview.superview convertRect:subview.frame toView:frameView];
		
		NSValue *rectValue = [NSValue valueWithCGRect:rect];
		[self.frameView.rectsToOutline addObject:rectValue];
		[self addOutlinesToFrameViewFromSubview:subview];
	}
}

- (void)toggleOpaqueViews
{
	self.highlightOpaqueViews = !self.highlightOpaqueViews;

	UIWindow *mainWindow = [self mainWindow];
	[self setBackgroundColor:(self.highlightOpaqueViews) ? [UIColor redColor] : [UIColor clearColor]
	  ofOpaqueViewsInSubview:mainWindow];

	NSString *string = [NSString stringWithFormat:@"Highlighting opaque views is %@", (self.highlightOpaqueViews) ? @"on" : @"off"];
	if (self.showStatusBarOverlay)
		[self showTemporaryStringInStatusBar:string];
	else
		NSLog(@"%@", string);
}

- (void)setBackgroundColor:(UIColor *)color ofOpaqueViewsInSubview:(UIView *)view
{
	for (UIView *subview in view.subviews)
	{
		if ([self ignoreView:subview])
			continue;
		
		if (!subview.opaque)
			subview.backgroundColor = color;
		
		[self setBackgroundColor:color ofOpaqueViewsInSubview:subview];
	}
}

- (void)toggleRedrawFlashing
{
	self.flashOnRedraw = !self.flashOnRedraw;
	NSString *string = [NSString stringWithFormat:@"Flashing on redraw is %@", (self.flashOnRedraw) ? @"on" : @"off"];
	if (self.showStatusBarOverlay)
		[self showTemporaryStringInStatusBar:string];
	else
		NSLog(@"%@", string);

	// flash all views to show what is working
	[self callDrawRectOnViewsInSubview:[self mainWindow]];
}

- (void)callDrawRectOnViewsInSubview:(UIView *)subview
{
	for (UIView *view in subview.subviews)
	{
		if (![self ignoreView:view])
		{
			[view setNeedsDisplay];
			[self callDrawRectOnViewsInSubview:view];
		}
	}
}

- (void)flashRect:(CGRect)rect inView:(UIView *)view
{
	if (self.flashOnRedraw)
	{
		CALayer *layer = [CALayer layer];
		layer.frame = rect;
		layer.backgroundColor = kDCIntrospectFlashOnRedrawColor.CGColor;
		[view.layer addSublayer:layer];
		[layer performSelector:@selector(removeFromSuperlayer) withObject:nil afterDelay:kDCIntrospectFlashOnRedrawFlashLength];
	}
}

#pragma mark Description Methods

- (NSString *)describeProperty:(NSString *)propertyName type:(NSString *)type value:(id)value
{
	if ([propertyName isEqualToString:@"contentMode"])
	{
		switch ((int)value)
		{
			case 0: return @"UIViewContentModeScaleToFill";
			case 1: return @"UIViewContentModeScaleAspectFit";
			case 2: return @"UIViewContentModeScaleAspectFill";
			case 3: return @"UIViewContentModeRedraw";
			case 4: return @"UIViewContentModeCenter";
			case 5: return @"UIViewContentModeTop";
			case 6: return @"UIViewContentModeBottom";
			case 7: return @"UIViewContentModeLeft";
			case 8: return @"UIViewContentModeRight";
			case 9: return @"UIViewContentModeTopLeft";
			case 10: return @"UIViewContentModeTopRight";
			case 11: return @"UIViewContentModeBottomLeft";
			case 12: return @"UIViewContentModeBottomRight";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"textAlignment"])
	{
		switch ((int)value)
		{
			case 0: return @"UITextAlignmentLeft";
			case 1: return @"UITextAlignmentCenter";
			case 2: return @"UITextAlignmentRight";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"lineBreakMode"])
	{
		switch ((int)value)
		{
			case 0: return @"UILineBreakModeWordWrap";
			case 1: return @"UILineBreakModeCharacterWrap";
			case 2: return @"UILineBreakModeClip";
			case 3: return @"UILineBreakModeHeadTruncation";
			case 4: return @"UILineBreakModeTailTruncation";
			case 5: return @"UILineBreakModeMiddleTruncation";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"activityIndicatorViewStyle"])
	{
		switch ((int)value)
		{
			case 0: return @"UIActivityIndicatorViewStyleWhiteLarge";
			case 1: return @"UIActivityIndicatorViewStyleWhite";
			case 2: return @"UIActivityIndicatorViewStyleGray";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"returnKeyType"])
	{
		switch ((int)value)
		{
			case 0: return @"UIReturnKeyDefault";
			case 1: return @"UIReturnKeyGo";
			case 2: return @"UIReturnKeyGoogle";
			case 3: return @"UIReturnKeyJoin";
			case 4: return @"UIReturnKeyNext";
			case 5: return @"UIReturnKeyRoute";
			case 6: return @"UIReturnKeySearch";
			case 7: return @"UIReturnKeyYahoo";
			case 8: return @"UIReturnKeyDone";
			case 9: return @"UIReturnKeyEmergencyCall";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"keyboardAppearance"])
	{
		switch ((int)value)
		{
			case 0: return @"UIKeyboardAppearanceDefault";
			case 1: return @"UIKeyboardAppearanceAlert";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"keyboardType"])
	{
		switch ((int)value)
		{
			case 0: return @"UIKeyboardTypeDefault";
			case 1: return @"UIKeyboardTypeASCIICapable";
			case 2: return @"UIKeyboardTypeNumbersAndPunctuation";
			case 3: return @"UIKeyboardTypeURL";
			case 4: return @"UIKeyboardTypeNumberPad";
			case 5: return @"UIKeyboardTypePhonePad";
			case 6: return @"UIKeyboardTypeNamePhonePad";
			case 7: return @"UIKeyboardTypeEmailAddress";
			case 8: return @"UIKeyboardTypeDecimalPad";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"autocorrectionType"])
	{
		switch ((int)value)
		{
			case 0: return @"UIKeyboardTypeDefault";
			case 1: return @"UITextAutocorrectionTypeDefault";
			case 2: return @"UITextAutocorrectionTypeNo";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"autocapitalizationType"])
	{
		switch ((int)value)
		{
			case 0: return @"UITextAutocapitalizationTypeNone";
			case 1: return @"UITextAutocapitalizationTypeWords";
			case 2: return @"UITextAutocapitalizationTypeSentences";
			case 3: return @"UITextAutocapitalizationTypeAllCharacters";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"clearButtonMode"] ||
			 [propertyName isEqualToString:@"leftViewMode"] ||
			 [propertyName isEqualToString:@"rightViewMode"])
	{
		switch ((int)value)
		{
			case 0: return @"UITextFieldViewModeNever";
			case 1: return @"UITextFieldViewModeWhileEditing";
			case 2: return @"UITextFieldViewModeUnlessEditing";
			case 3: return @"UITextFieldViewModeAlways";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"borderStyle"])
	{
		switch ((int)value)
		{
			case 0: return @"UITextBorderStyleNone";
			case 1: return @"UITextBorderStyleLine";
			case 2: return @"UITextBorderStyleBezel";
			case 3: return @"UITextBorderStyleRoundedRect";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"progressViewStyle"])
	{
		switch ((int)value)
		{
			case 0: return @"UIProgressViewStyleBar";
			case 1: return @"UIProgressViewStyleDefault";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"separatorStyle"])
	{
		switch ((int)value)
		{
			case 0: return @"UITableViewCellSeparatorStyleNone";
			case 1: return @"UITableViewCellSeparatorStyleSingleLine";
			case 2: return @"UITableViewCellSeparatorStyleSingleLineEtched";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"selectionStyle"])
	{
		switch ((int)value)
		{
			case 0: return @"UITableViewCellSelectionStyleNone";
			case 1: return @"UITableViewCellSelectionStyleBlue";
			case 2: return @"UITableViewCellSelectionStyleGray";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"editingStyle"])
	{
		switch ((int)value)
		{
			case 0: return @"UITableViewCellEditingStyleNone";
			case 1: return @"UITableViewCellEditingStyleDelete";
			case 2: return @"UITableViewCellEditingStyleInsert";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"accessoryType"] || [propertyName isEqualToString:@"editingAccessoryType"])
	{
		switch ((int)value)
		{
			case 0: return @"UITableViewCellAccessoryNone";
			case 1: return @"UITableViewCellAccessoryDisclosureIndicator";
			case 2: return @"UITableViewCellAccessoryDetailDisclosureButton";
			case 3: return @"UITableViewCellAccessoryCheckmark";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"style"])
	{
		switch ((int)value)
		{
			case 0: return @"UITableViewStylePlain";
			case 1: return @"UITableViewStyleGrouped";
			default: return nil;
		}

	}
	else if ([propertyName isEqualToString:@"autoresizingMask"])
	{
		UIViewAutoresizing mask = (int)value;
		NSMutableString *string = [NSMutableString string];
		if (mask & UIViewAutoresizingFlexibleLeftMargin)
			[string appendFormat:@"UIViewAutoresizingFlexibleLeftMargin"];
		if (mask & UIViewAutoresizingFlexibleRightMargin)
			[string appendFormat:@" | UIViewAutoresizingFlexibleRightMargin"];
		if (mask & UIViewAutoresizingFlexibleTopMargin)
			[string appendFormat:@" | UIViewAutoresizingFlexibleTopMargin"];
		if (mask & UIViewAutoresizingFlexibleBottomMargin)
			[string appendFormat:@" | UIViewAutoresizingFlexibleBottomMargin"];
		if (mask & UIViewAutoresizingFlexibleWidth)
			[string appendFormat:@" | UIViewAutoresizingFlexibleWidthMargin"];
		if (mask & UIViewAutoresizingFlexibleHeight)
			[string appendFormat:@" | UIViewAutoresizingFlexibleHeightMargin"];
		
		if ([string hasPrefix:@" | "])
			[string replaceCharactersInRange:NSMakeRange(0, 3) withString:@""];

		return string;
	}
	else if ([propertyName isEqualToString:@"userInteractionEnabled"] ||
			 [propertyName isEqualToString:@"enabled"] ||
			 [propertyName isEqualToString:@"highlighted"] ||
			 [propertyName isEqualToString:@"selected"] ||
			 [propertyName isEqualToString:@"continuous"] ||
			 [propertyName isEqualToString:@"on"] ||
			 [propertyName isEqualToString:@"secureTextEntry"] ||
			 [propertyName isEqualToString:@"enablesReturnKeyAutomatically"] ||
			 [propertyName isEqualToString:@"keepsFirstResponderVisibleOnBoundsChange"] ||
			 [propertyName isEqualToString:@"editing"] ||
			 [propertyName isEqualToString:@"needsSetup"] ||
			 [propertyName isEqualToString:@"drawsTopShadow"])
	{
		return ((int)value) ? @"YES" : @"NO";
	}

	// print out the return for each value depending on type
	if ([type isEqualToString:@"f"])
	{
		return [NSString stringWithFormat:@"%f", value];
	}
	else if ([type isEqualToString:@"d"])
	{
		return [NSString stringWithFormat:@"%d", value];
	}
	else if ([type isEqualToString:@"i"] || [type isEqualToString:@"I"])
	{
		return [NSString stringWithFormat:@"%i", value];
	}
	else if ([type isEqualToString:@"c"])
	{
		return [NSString stringWithFormat:@"%@", (value) ? @"YES" : @"NO"];
	}
	else if ([type isEqualToString:@"@"])
	{
		if ([NSStringFromClass([value class]) isEqualToString:@"UIDeviceRGBColor"])
		{
			UIColor *color = (UIColor *)value;
			return [self describeColor:color];
		}
		else if ([NSStringFromClass([value class]) isEqualToString:@"UICFFont"])
		{
			UIFont *font = (UIFont *)value;
			return [NSString stringWithFormat:@"%.0fpx %@", font.pointSize, font.fontName];
		}
		else
		{
			return [NSString stringWithFormat:@"%@", value];
		}
	}
	else if ([type isEqualToString:@"{CGSize=ff}"])
	{
		NSValue *sizeValue = (NSValue *)value;
		if (!sizeValue)
			return @"CGSizeZero";
		CGSize size = [sizeValue CGSizeValue];
		return [NSString stringWithFormat:@"%@", NSStringFromCGSize(size)];
	}
	else if ([type isEqualToString:@"{UIEdgeInsets=ffff}"])
	{
		NSValue *editInsetsValue = (NSValue *)value;
		UIEdgeInsets edgeInsets = [editInsetsValue UIEdgeInsetsValue];
		return [NSString stringWithFormat:@"%@", NSStringFromUIEdgeInsets(edgeInsets)];
	}
	else
	{
		return [NSString stringWithFormat:@"(unknown type: %@)", type];
	}

	return nil;
}

- (NSString *)describeColor:(UIColor *)color
{
	NSString *returnString = nil;
	if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelRGB)
	{
		const CGFloat *components = CGColorGetComponents(color.CGColor);
		returnString = [NSString stringWithFormat:@"R: %.0f G: %.0f B: %.0f A: %.2f",
						components[0] * 256,
						components[1] * 256,
						components[2] * 256,
						components[3]];
	}
	else
	{
		returnString = [NSString stringWithFormat:@"%@ (incompatible color space)", color];
	}
	return returnString;
}

#pragma mark DCIntrospector Help

- (void)toggleHelp
{
	UIWindow *mainWindow = [self mainWindow];
	self.showingHelp = !self.showingHelp;

	if (self.showingHelp)
	{
		self.statusBarOverlay.leftLabel.text = @"Help";
		self.statusBarOverlay.rightLabel.text = @"Close";
		UIView *backingView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, mainWindow.frame.size.width, mainWindow.frame.size.height)] autorelease];
		backingView.tag = 1548;
		backingView.alpha = 0;
		backingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.85];
		[mainWindow addSubview:backingView];

		UIWebView *webView = [[[UIWebView alloc] initWithFrame:backingView.frame] autorelease];
		webView.opaque = NO;
		webView.backgroundColor = [UIColor clearColor];
		webView.delegate = self;
		[backingView addSubview:webView];

		NSMutableString *helpString = [NSMutableString stringWithString:@"<html>"];
		[helpString appendString:@"<head><style>"];
		[helpString appendString:@"body { background-color:rgba(0, 0, 0, 0.0); font:10pt helvetica; line-height: 15px margin-left:5px; margin-right:5px; margin-top:20px; color:rgb(240, 240, 240); } a { color:white; font-weight:bold; } h1 { width:100%; font-size:14pt; border-bottom: 1px solid white; margin-top:22px; } h2 { font-size:11pt; margin-left:3px; margin-bottom:2px; } .name { margin-left:7px; } .key { float:right; margin-right:7px; } .key, .code { font-family:Courier; font-weight:bold; } .spacer { height:10px; } p { margin-left: 7px; margin-right: 7px; }"];

		if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
			[helpString appendString:@"body { font-size:11pt; width:500px; margin:0 auto; }"];

		[helpString appendString:@"</style></head><body><h1>DCIntrospect</h1>"];
		[helpString appendString:@"<p>Created by <a href='http://domesticcat.com.au'>Domestic Cat Software</a> 2011.</p>"];
		[helpString appendString:@"<p>More info and full documentation: <a href='http://domesticcat.com.au/introspect'>domesticcat.com.au/introspect</a></p>"];
		[helpString appendString:@"<p>GitHub project: <a href='https://github.com/domesticcatsoftware/DCIntrospect'>github.com/domesticcatsoftware/DCIntrospect/</a></p>"];

		[helpString appendString:@"<div class='bindings'><h1>Key Bindings</h1>"];
		[helpString appendString:@"<p>Edit DCIntrospectSettings.h to change key bindings.</p>"];

		[helpString appendString:@"<h2>General</h2>"];

		[helpString appendFormat:@"<div><span class='name'>Invoke Introspector</span><div class='key'>%@</div></div>", ([kDCIntrospectKeysInvoke isEqualToString:@" "]) ? @"spacebar" : kDCIntrospectKeysInvoke];
		[helpString appendFormat:@"<div><span class='name'>Toggle View Outlines</span><div class='key'>%@</div></div>",kDCIntrospectKeysToggleViewOutlines];
		[helpString appendFormat:@"<div><span class='name'>Toggle Highlighting Non-Opaque Views</span><div class='key'>%@</div></div>",kDCIntrospectKeysToggleNonOpaqueViews];
		[helpString appendFormat:@"<div><span class='name'>Toggle Help</span><div class='key'>%@</div></div>",kDCIntrospectKeysToggleHelp];
		[helpString appendFormat:@"<div><span class='name'>Toggle flash on <span class='code'>drawRect:</span> (see below)</span><div class='key'>%@</div></div>",kDCIntrospectKeysToggleFlashViewRedraws];
		[helpString appendFormat:@"<div><span class='name'>Toggle coordinates</span><div class='key'>%@</div></div>",kDCIntrospectKeysToggleShowCoordinates];
		[helpString appendFormat:@"<div><span class='name'>Block mode</span><div class='key'>%@</div></div>", kDCIntrospectKeysEnterBlockMode];
		[helpString appendString:@"<div class='spacer'></div>"];

		[helpString appendString:@"<h2>When a view is selected</h2>"];
		[helpString appendFormat:@"<div><span class='name'>Log Properties</span><div class='key'>%@</div></div>",kDCIntrospectKeysLogProperties];
		[helpString appendFormat:@"<div><span class='name'>Log Recursive Description for View</span><div class='key'>%@</div></div>",kDCIntrospectKeysLogViewRecursive];
		[helpString appendFormat:@"<div><span class='name'>Select View's Superview</span><div class='key'>%@</div></div>", ([kDCIntrospectKeysSelectMoveUpViewHeirachy isEqualToString:@""]) ? @"page up" : kDCIntrospectKeysSelectMoveUpViewHeirachy];
		[helpString appendString:@"<div class='spacer'></div>"];

		[helpString appendFormat:@"<div><span class='name'>Nudge Left</span><div class='key'>%@</div></div>",kDCIntrospectKeysNudgeViewLeft];
		[helpString appendFormat:@"<div><span class='name'>Nudge Right</span><div class='key'>%@</div></div>",kDCIntrospectKeysNudgeViewRight];
		[helpString appendFormat:@"<div><span class='name'>Nudge Up</span><div class='key'>%@</div></div>",kDCIntrospectKeysNudgeViewUp];
		[helpString appendFormat:@"<div><span class='name'>Nudge Down</span><div class='key'>%@</div></div>",kDCIntrospectKeysNudgeViewDown];
		[helpString appendFormat:@"<div><span class='name'>Center in Superview</span><div class='key'>%@</div></div>",kDCIntrospectKeysCenterInSuperview];
		[helpString appendFormat:@"<div><span class='name'>Increase Width</span><div class='key'>%@</div></div>",kDCIntrospectKeysIncreaseWidth];
		[helpString appendFormat:@"<div><span class='name'>Decrease Width</span><div class='key'>%@</div></div>",kDCIntrospectKeysDecreaseWidth];
		[helpString appendFormat:@"<div><span class='name'>Increase Height</span><div class='key'>%@</div></div>",kDCIntrospectKeysIncreaseHeight];
		[helpString appendFormat:@"<div><span class='name'>Decrease Height</span><div class='key'>%@</div></div>",kDCIntrospectKeysDecreaseHeight];
		[helpString appendFormat:@"<div><span class='name'>Increase Alpha</span><div class='key'>%@</div></div>",kDCIntrospectKeysIncreaseViewAlpha];
		[helpString appendFormat:@"<div><span class='name'>Decrease Alpha</span><div class='key'>%@</div></div>",kDCIntrospectKeysDecreaseViewAlpha];
		[helpString appendString:@"<div class='spacer'></div>"];

		[helpString appendFormat:@"<div><span class='name'>Call setNeedsDisplay</span><div class='key'>%@</div></div>",kDCIntrospectKeysSetNeedsDisplay];
		[helpString appendFormat:@"<div><span class='name'>Call setNeedsLayout</span><div class='key'>%@</div></div>",kDCIntrospectKeysSetNeedsLayout];
		[helpString appendFormat:@"<div><span class='name'>Call reloadData (UITableView only)</span><div class='key'>%@</div></div>",kDCIntrospectKeysReloadData];
		[helpString appendString:@"</div>"];

		[helpString appendFormat:@"<h1>Flash on <span class='code'>drawRect:</span> calls</h1><p>To implement, call <span class='code'>[[DCIntrospect sharedIntrospector] flashRect:inView:]</span> inside the <span class='code'>drawRect:</span> method of any view you want to track.</p><p>When Flash on <span class='code'>drawRect:</span> is toggled on (binding: <span class='code'>%@</span>) the view will flash whenever <span class='code'>drawRect:</span> is called.</p>", kDCIntrospectKeysToggleFlashViewRedraws];

		[helpString appendFormat:@"<h1>Block mode</h1><p>Add blocks using <span class='code'>[[DCIntrospect sharedIntrospector] addBlock:withName:keyBinding:]</span></p><p>After entering Block mode (key binding: <span class='code'>%@</span>), push the key binding set for the block to run the block.</p>", kDCIntrospectKeysEnterBlockMode];

		[helpString appendString:@"<h1>License</h1><p>DCIntrospect is made available under the <a href='http://en.wikipedia.org/wiki/MIT_License'>MIT license</a>.</p>"];

		[helpString appendString:@"<h2 style='text-align:center;'><a href='http://close'>Close Help</h2>"];
		[helpString appendString:@"<div class='spacer'></div>"];

		[UIView animateWithDuration:0.1
						 animations:^{
							 backingView.alpha = 1.0;
						 } completion:^(BOOL finished) {
							 [webView loadHTMLString:helpString baseURL:nil];
						 }];
	}
	else
	{
		UIView *backingView = (UIView *)[mainWindow viewWithTag:1548];
		[UIView animateWithDuration:0.1
						 animations:^{
							 backingView.alpha = 0;
						 } completion:^(BOOL finished) {
							 [backingView removeFromSuperview];
						 }];
		[self updateStatusBar];
	}
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSString *requestString = [[request URL] absoluteString];
	if ([requestString isEqualToString:@"about:blank"])
		return YES;
	else if ([requestString isEqualToString:@"http://close/"])
		[self toggleHelp];
	else
		[[UIApplication sharedApplication] openURL:[request URL]];

	return NO;
}

#pragma mark Experimental

- (void)logPropertiesForCurrentView
{
	[self logPropertiesForObject:self.currentView];
}

- (void)logPropertiesForObject:(id)object
{
	Class objectClass = [object class];
	NSString *className = [NSString stringWithFormat:@"%@", objectClass];

	unsigned int count;
	objc_property_t *properties = class_copyPropertyList(objectClass, &count);
    size_t buf_size = 1024;
    char *buffer = malloc(buf_size);
	NSMutableString *outputString = [NSMutableString stringWithFormat:@"\n\n** %@", className];

	// list the class heirachy
	Class superClass = [objectClass superclass];
	while (superClass)
	{
		[outputString appendFormat:@" : %@", superClass];
		superClass = [superClass superclass];
	}

	[outputString appendString:@" ** \n\n"];

	if ([objectClass isSubclassOfClass:UIView.class])
	{
		UIView *view = (UIView *)object;
		// print out generic uiview properties
		[outputString appendString:@"  ** UIView properties **\n"];
		[outputString appendFormat:@"    tag: %i\n", view.tag];
		[outputString appendFormat:@"    frame: %@ | ", NSStringFromCGRect(view.frame)];
		[outputString appendFormat:@"bounds: %@ | ", NSStringFromCGRect(view.bounds)];
		[outputString appendFormat:@"center: %@\n", NSStringFromCGPoint(view.center)];
		[outputString appendFormat:@"    transform: %@\n", NSStringFromCGAffineTransform(view.transform)];
		[outputString appendFormat:@"    autoresizingMask: %@\n", [self describeProperty:@"autoresizingMask" type:@"autoresizingMask" value:(id)view.autoresizingMask]];
		[outputString appendFormat:@"    autoresizesSubviews: %@\n", (view.autoresizesSubviews) ? @"YES" : @"NO"];
		[outputString appendFormat:@"    contentMode: %@ | ", [self describeProperty:@"contentMode" type:nil value:(id)view.contentMode]];
		[outputString appendFormat:@"contentStretch: %@\n", NSStringFromCGRect(view.contentStretch)];
		[outputString appendFormat:@"    backgroundColor: %@\n", [self describeColor:view.backgroundColor]];
		[outputString appendFormat:@"    alpha: %.2f | ", view.alpha];
		[outputString appendFormat:@"opaque: %@ | ", (view.opaque) ? @"YES" : @"NO"];
		[outputString appendFormat:@"hidden: %@ | ", (view.hidden) ? @"YES" : @"NO"];
		[outputString appendFormat:@"clips to bounds: %@ | ", (view.clipsToBounds) ? @"YES" : @"NO"];
		[outputString appendFormat:@"clearsContextBeforeDrawing: %@\n", (view.clearsContextBeforeDrawing) ? @"YES" : @"NO"];
		[outputString appendFormat:@"    userInteractionEnabled: %@ | ", (view.userInteractionEnabled) ? @"YES" : @"NO"];
		[outputString appendFormat:@"multipleTouchEnabled: %@\n", (view.multipleTouchEnabled) ? @"YES" : @"NO"];
		[outputString appendFormat:@"    gestureRecognizers: %@\n", view.gestureRecognizers];

		[outputString appendString:@"\n"];
	}

	[outputString appendFormat:@"  ** %@ properties **\n", objectClass];

	if (objectClass == UIScrollView.class || objectClass == UIButton.class)
	{
		[outputString appendString:@"    Logging properties not currently supported for this view.\n"];
	}
	else
	{

		for (unsigned int i = 0; i < count; ++i)
		{
			// get the property name and selector name
			NSString *propertyName = [NSString stringWithCString:property_getName(properties[i]) encoding:NSUTF8StringEncoding];
			
			// get the return object and type for the selector
			SEL sel = NSSelectorFromString(propertyName);
			Method method = class_getInstanceMethod(objectClass, sel);
			id returnObject = ([object respondsToSelector:sel]) ? [object performSelector:sel] : nil;
			method_getReturnType(method, buffer, buf_size);
			NSString *returnType = [NSString stringWithFormat:@"%s", buffer];
			
			[outputString appendFormat:@"    %@: ", propertyName];
			NSString *propertyDescription = [self describeProperty:propertyName type:returnType value:returnObject];
			[outputString appendFormat:@"%@\n", propertyDescription];
		}
	}

	// list all targets if there are any
	if ([object respondsToSelector:@selector(allTargets)])
	{
		[outputString appendString:@"\n  ** Targets & Actions **\n"];
		UIControl *control = (UIControl *)object;
		UIControlEvents controlEvents = [control allControlEvents];
		NSSet *allTargets = [control allTargets];
		[allTargets enumerateObjectsUsingBlock:^(id target, BOOL *stop)
		 {
			 NSArray *actions = [control actionsForTarget:target forControlEvent:controlEvents];
			 [actions enumerateObjectsUsingBlock:^(id action, NSUInteger idx, BOOL *stop)
			  {
				  [outputString appendFormat:@"    target: %@ action: %@\n", target, action];
			  }];
		 }];
	}

	[outputString appendString:@"\n"];
	NSLog(@"%@", outputString);
	
	free(properties);
    free(buffer);
}

- (BOOL)ignoreView:(UIView *)view
{
	if (view == self.frameView || view == self.toolbar || view == self.inputField)
		return YES;
	
	NSArray *classNamesToIgnore = [NSArray arrayWithObjects:
								   @"UIDatePickerView",
								   @"UIPickerTable",
								   @"UIWeekMonthDayTableCell",
								   nil];
	NSString *className = NSStringFromClass([view class]);
	return [classNamesToIgnore containsObject:className];
}

- (NSArray *)subclassesOfClass:(Class)parentClass
{
	// thanks to Matt Gallagher:
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
	
    classes = malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++)
    {
        Class superClass = classes[i];
        do
        {
            superClass = class_getSuperclass(superClass);
        } while(superClass && superClass != parentClass);
        
        if (superClass == nil)
        {
            continue;
        }
        
        [result addObject:classes[i]];
    }
	
    free(classes);
    
    return result;
}

#pragma mark Helper Methods

- (UIWindow *)mainWindow
{
	NSArray *windows = [[UIApplication sharedApplication] windows];
	if (windows.count == 0)
		return nil;
	
	return [windows objectAtIndex:0];
}

- (NSMutableArray *)viewsAtPoint:(CGPoint)touchPoint inView:(UIView *)view
{
	NSMutableArray *views = [[NSMutableArray alloc] init];
	for (UIView *subview in view.subviews)
	{
		CGRect rect = subview.frame;
		if ([self ignoreView:subview])
			continue;

		if (CGRectContainsPoint(rect, touchPoint))
		{
			[views addObject:subview];

			// convert the point to it's superview
			CGPoint newTouchPoint = touchPoint;
			newTouchPoint = [view convertPoint:newTouchPoint toView:subview];
			[views addObjectsFromArray:[self viewsAtPoint:newTouchPoint inView:subview]];
		}
	}
	
	return [views autorelease];
}

- (void)fadeView:(UIView *)view toAlpha:(CGFloat)alpha
{
	[UIView animateWithDuration:0.1
						  delay:0.0
						options:UIViewAnimationOptionAllowUserInteraction
					 animations:^{
						 view.alpha = alpha;
					 }
					 completion:nil];
}

- (BOOL)view:(UIView *)view containsSubview:(UIView *)subview
{
	for (UIView *aView in view.subviews)
	{
		if (aView == subview)
			return YES;

		if ([self view:aView containsSubview:subview])
			return YES;
	}

	return NO;
}

@end
