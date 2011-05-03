//
//  DCIntrospect.m
//
//  Created by Domestic Cat on 29/04/11.
//

#import "DCIntrospect.h"

DCIntrospect *sharedInstance = nil;

@implementation DCIntrospect
@synthesize keyboardShortcuts, showStatusBarOverlay, gestureRecognizer;
@synthesize on;
@synthesize viewOutlines, highlightOpaqueViews, flashOnRedraw;
@synthesize statusBarOverlay;
@synthesize inputField;
@synthesize toolbar;
@synthesize frameView;

@synthesize currentView;
@synthesize originalFrame, originalAlpha;

+ (DCIntrospect *)sharedIntrospector
{
#ifdef DEBUG
	if (!sharedInstance)
	{
		sharedInstance = [[DCIntrospect alloc] init];
		sharedInstance.keyboardShortcuts = YES;
		sharedInstance.showStatusBarOverlay = YES;

		UITapGestureRecognizer *defaultGestureRecognizer = [[[UITapGestureRecognizer alloc] init] autorelease];
		defaultGestureRecognizer.cancelsTouchesInView = NO;
		defaultGestureRecognizer.delaysTouchesBegan = NO;
		defaultGestureRecognizer.delaysTouchesEnded = NO;
		defaultGestureRecognizer.numberOfTapsRequired = 2;
		defaultGestureRecognizer.numberOfTouchesRequired = 1;
		sharedInstance.gestureRecognizer = defaultGestureRecognizer;
	}
#endif

	return sharedInstance;
}

- (void)setGestureRecognizer:(UIGestureRecognizer *)newGestureRecognizer
{
	UIWindow *mainWindow = [self mainWindow];
	[mainWindow removeGestureRecognizer:gestureRecognizer];

	[gestureRecognizer release];
	gestureRecognizer = nil;
	gestureRecognizer = [newGestureRecognizer retain];
	[gestureRecognizer addTarget:self action:@selector(introspectorInvoked:)];
	[mainWindow addGestureRecognizer:newGestureRecognizer];
}

- (void)start
{
	UIWindow *mainWindow = [self mainWindow];
	if (!mainWindow)
	{
		NSLog(@"DCIntrospector: Couldn't start.  No main window?");
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

	if (keyboardShortcuts)
		[self.inputField becomeFirstResponder];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarTapped) name:kDCIntrospectNotificationStatusBarTapped object:nil];

	[[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification
													  object:nil
													   queue:nil
												  usingBlock:^(NSNotification *notification) {
													  // needs to be done after a delay or else it doesn't work.
													  [self.inputField performSelector:@selector(becomeFirstResponder)
																			withObject:nil
																			afterDelay:0.1];
												  }];

	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatusBarFrame) name:UIDeviceOrientationDidChangeNotification object:nil];

}

#pragma mark Introspector

- (void)introspectorInvoked:(UIGestureRecognizer *)aGestureRecognizer
{
	self.on = !self.on;

	if (self.on)
	{
		[self updateStatusBarFrame];
		[self updateStatusBar];
		[self updateFrameView];

		if (keyboardShortcuts)
			[self.inputField becomeFirstResponder];
		else
			[self.inputField resignFirstResponder];
	}
	else
	{
		self.toolbar.alpha = 0;
		if (self.viewOutlines)
			[self toggleOutlines];
		if (self.highlightOpaqueViews)
			[self toggleOpaqueViews];

		self.statusBarOverlay.hidden = YES;
		self.frameView.alpha = 0;
		self.currentView = nil;
	}

	if (aGestureRecognizer)
	{
		CGPoint touchPoint = [gestureRecognizer locationInView:nil];
		[self touchAtPoint:touchPoint];
	}
}

- (void)updateFrameView
{
	UIWindow *mainWindow = [self mainWindow];
	if (!self.frameView)
	{
		self.frameView = [[[DCFrameView alloc] initWithFrame:(CGRect){ CGPointZero, mainWindow.frame.size } delegate:self] autorelease];
		[mainWindow addSubview:self.frameView];
		self.frameView.alpha = 0.0;
		[self updateStatusBarFrame];
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
	if (self.currentView)
	{
		if (self.currentView.tag != 0)
			self.statusBarOverlay.leftLabel.text = [NSString stringWithFormat:@"%@ (tag: %i)", [self.currentView class], self.currentView.tag];
		else
			self.statusBarOverlay.leftLabel.text = [NSString stringWithFormat:@"%@", [self.currentView class]];

		self.statusBarOverlay.rightLabel.text = NSStringFromCGRect(self.currentView.frame);
		self.statusBarOverlay.infoButton.hidden = YES;
	}
	else
	{
		self.statusBarOverlay.leftLabel.text = @"DCIntrospector";
		self.statusBarOverlay.infoButton.hidden = NO;
	}

	if (self.showStatusBarOverlay)
		self.statusBarOverlay.hidden = NO;
	else
		self.statusBarOverlay.hidden = YES;
}

- (void)updateStatusBarFrame
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
		self.frameView.frame = CGRectMake(screenWidth - screenHeight, 0, screenHeight - statusBarSize.width, screenHeight);
		self.toolbar.transform = self.frameView.transform;
		self.toolbar.frame = CGRectMake(screenWidth - statusBarSize.width - toolbarSize.height, 0, toolbarSize.height, screenHeight);
	}
	else if (orientation == UIDeviceOrientationLandscapeRight)
	{
		self.frameView.transform = CGAffineTransformMakeRotation(pi * (-90) / 180.0f);
		self.frameView.frame = CGRectMake(statusBarSize.width, 0, screenWidth, screenHeight);
		self.toolbar.transform = self.frameView.transform;
		self.toolbar.frame = CGRectMake(statusBarSize.width, 0, toolbarSize.height, screenHeight);
	}
	else if (orientation == UIDeviceOrientationPortraitUpsideDown)
	{
		self.frameView.transform = CGAffineTransformMakeRotation(pi);
		self.frameView.frame = CGRectMake(0, 0, screenWidth, screenHeight - statusBarSize.height);
		self.toolbar.transform = self.frameView.transform;
		self.toolbar.frame = CGRectMake(0, screenHeight - statusBarSize.height - toolbarSize.height, screenWidth, toolbarSize.height);
	}

	self.currentView = nil;
	[self updateFrameView];
}

- (void)touchAtPoint:(CGPoint)point
{
	NSMutableArray *views = [[NSMutableArray new] autorelease];
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

#pragma mark Tools

- (void)statusBarTapped
{
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

			[self updateStatusBarFrame];
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
	else
	{
		[self showHelp];
	}
}

- (void)updateToolbar
{
	// setup toolbar
	[self.toolbar.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[(UIView *)obj removeFromSuperview];
	}];

	NSMutableArray *buttons = [[NSMutableArray new] autorelease];
	
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
		[reloadTableView addTarget:self action:@selector(forceReload) forControlEvents:UIControlEventTouchUpInside];
		[buttons addObject:reloadTableView];
	}

	CGFloat x = 0;
	for (UIButton *button in buttons)
	{
		button.titleLabel.font = [UIFont systemFontOfSize:12.0];
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

- (void)logRecursiveDescriptionForCurrentView
{
#ifdef DEBUG
	// [UIView recursiveDescription] is a private method.
	NSLog(@"%@", [self.currentView recursiveDescription]);
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

- (void)forceReload
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

	UIWindow *mainWindow = [self mainWindow];
	[self setRedrawFlash:self.flashOnRedraw inViewsInSubview:mainWindow];
}

- (void)setRedrawFlash:(BOOL)redrawFlash inViewsInSubview:(UIView *)view
{
	for (UIView *subview in view.subviews)
	{
		if ([self ignoreView:subview])
			continue;

		[self setRedrawFlash:redrawFlash inViewsInSubview:subview];
	}
}

#pragma mark Description Methods

- (NSString *)describeProperty:(NSString *)propertyName value:(int)value
{
	if ([propertyName isEqualToString:@"contentMode"])
	{
		switch (value)
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
		switch (value)
		{
			case 0: return @"UITextAlignmentLeft";
			case 1: return @"UITextAlignmentCenter";
			case 2: return @"UITextAlignmentRight";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"lineBreakMode"])
	{
		switch (value)
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
		switch (value)
		{
			case 0: return @"UIActivityIndicatorViewStyleWhiteLarge";
			case 1: return @"UIActivityIndicatorViewStyleWhite";
			case 2: return @"UIActivityIndicatorViewStyleGray";
			default: return nil;
		}
	}
	else if ([propertyName isEqualToString:@"autoresizingMask"])
	{
		UIViewAutoresizing mask = value;
		NSMutableString *string = [[NSMutableString new] autorelease];
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

- (void)showHelp
{
	NSLog(@"Showing help");
}

#pragma mark Experimental

- (void)logPropertiesForCurrentView
{
	NSString *className = [NSString stringWithFormat:@"%@", [self.currentView class]];
	Class currentViewClass = [self.currentView class];

	if (currentViewClass == [UIScrollView class])
	{
		NSLog(@"DCIntrospect: Logging properties not supported for this view.");
		return;
	}

	unsigned int count;
	objc_property_t *properties = class_copyPropertyList(currentViewClass, &count);
    size_t buf_size = 1024;
    char *buffer = malloc(buf_size);
	NSMutableString *outputString = [[[NSMutableString alloc] initWithFormat:@"\n\n** %@", className] autorelease];
	
	// list the class heirachy
	Class class = [currentViewClass superclass];
	while (class)
	{
		[outputString appendFormat:@" : %@", class];
		class = [class superclass];
	}
	
	[outputString appendString:@" ** \n\n"];
	
	// print out generic uiview properties
	[outputString appendString:@"  ** UIView properties **\n"];
	[outputString appendFormat:@"    tag: %i\n", self.currentView.tag];
	[outputString appendFormat:@"    frame: %@ | ", NSStringFromCGRect(self.currentView.frame)];
	[outputString appendFormat:@"bounds: %@ | ", NSStringFromCGRect(self.currentView.bounds)];
	[outputString appendFormat:@"center: %@\n", NSStringFromCGPoint(self.currentView.center)];
	[outputString appendFormat:@"    transform: %@\n", NSStringFromCGAffineTransform(self.currentView.transform)];
	[outputString appendFormat:@"    autoresizingMask: %@\n", [self describeProperty:@"autoresizingMask" value:self.currentView.autoresizingMask]];
	[outputString appendFormat:@"    autoresizesSubviews: %@\n", (self.currentView.autoresizesSubviews) ? @"YES" : @"NO"];
	[outputString appendFormat:@"    contentMode: %@ | ", [self describeProperty:@"contentMode" value:self.currentView.contentMode]];
	[outputString appendFormat:@"contentStretch: %@\n", NSStringFromCGRect(self.currentView.contentStretch)];
	[outputString appendFormat:@"    backgroundColor: %@\n", [self describeColor:self.currentView.backgroundColor]];
	[outputString appendFormat:@"    alpha: %.2f | ", self.currentView.alpha];
	[outputString appendFormat:@"opaque: %@ | ", (self.currentView.opaque) ? @"YES" : @"NO"];
	[outputString appendFormat:@"hidden: %@ | ", (self.currentView.hidden) ? @"YES" : @"NO"];
	[outputString appendFormat:@"clips to bounds: %@ | ", (self.currentView.clipsToBounds) ? @"YES" : @"NO"];
	[outputString appendFormat:@"clearsContextBeforeDrawing: %@\n", (self.currentView.clearsContextBeforeDrawing) ? @"YES" : @"NO"];
	[outputString appendFormat:@"    userInteractionEnabled: %@ | ", (self.currentView.userInteractionEnabled) ? @"YES" : @"NO"];
	[outputString appendFormat:@"multipleTouchEnabled: %@\n", (self.currentView.multipleTouchEnabled) ? @"YES" : @"NO"];
	[outputString appendFormat:@"    gestureRecognizers: %@\n", self.currentView.gestureRecognizers];

	[outputString appendString:@"\n"];
	[outputString appendFormat:@"  ** %@ properties **\n", currentViewClass];
	for (unsigned int i = 0; i < count; ++i)
	{
		// get the property name and selector name
		NSString *propertyName = [NSString stringWithCString:property_getName(properties[i]) encoding:NSUTF8StringEncoding];
		
		// get the return object and type for the selector
		SEL sel = NSSelectorFromString(propertyName);
		Method method = class_getInstanceMethod([self.currentView class], sel);
		id returnObject = ([self.currentView respondsToSelector:sel]) ? [self.currentView performSelector:sel] : nil;
		method_getReturnType(method, buffer, buf_size);
		NSString *returnType = [NSString stringWithFormat:@"%s", buffer];
		
		[outputString appendFormat:@"    %@: ", propertyName];
		// print out the return for each value depending on type
		if ([returnType isEqualToString:@"f"])
		{
			[outputString appendFormat:@"%f", returnObject];
		}
		else if ([returnType isEqualToString:@"i"] || [returnType isEqualToString:@"I"])
		{
			NSString *prettyDescription = [self describeProperty:propertyName value:(int)returnObject];
			if (prettyDescription)
				[outputString appendFormat:@"%@", prettyDescription];
			else
				[outputString appendFormat:@"%i", returnObject];
		}
		else if ([returnType isEqualToString:@"c"])
		{
			[outputString appendFormat:@"%@", (returnObject) ? @"YES" : @"NO"];
		}
		else if ([returnType isEqualToString:@"@"])
		{
			id returnObject = [self.currentView performSelector:sel];
			if ([NSStringFromClass([returnObject class]) isEqualToString:@"UIDeviceRGBColor"])
			{
				UIColor *color = (UIColor *)returnObject;
				[outputString appendString:[self describeColor:color]];
			}
			else if ([NSStringFromClass([returnObject class]) isEqualToString:@"UICFFont"])
			{
				UIFont *font = (UIFont *)returnObject;
				[outputString appendFormat:@"%.0fpx %@", font.pointSize, font.fontName];
			}
			else
			{
				[outputString appendFormat:@"%@", returnObject];
			}
		}
		else if ([returnType isEqualToString:@"{CGSize=ff}"])
		{
			NSValue *value = (NSValue *)returnObject;
			CGSize size = [value CGSizeValue];
			[outputString appendFormat:@"%@", NSStringFromCGSize(size)];
		}
		else if ([returnType isEqualToString:@"{UIEdgeInsets=ffff}"])
		{
			NSValue *value = (NSValue *)returnObject;
			UIEdgeInsets insets = [value UIEdgeInsetsValue];
			[outputString appendFormat:@"%@", NSStringFromUIEdgeInsets(insets)];
		}
		else if (returnType.length == 0)
		{
			// some properties have different getter names, often starting with is (for example: UILabel highlighed)
			// attempt to find the selector name
			NSString *newSelectorName = [NSString stringWithFormat:@"is%@%@", [[propertyName substringToIndex:1] uppercaseString], [propertyName substringFromIndex:1]];
			sel = NSSelectorFromString(newSelectorName);
			if ([self.currentView respondsToSelector:sel])
			{
				[outputString appendFormat:@"%@", ([self.currentView performSelector:sel]) ? @"YES" : @"NO"];
			}
			else
			{
				[outputString appendString:@"(unknown type)"];
			}
		}
		else
		{
			[outputString appendFormat:@"(unknown type: %@)", returnType];
		}
		[outputString appendString:@"\n"];
	}
	
	// list all targets if there are any
	if ([self.currentView respondsToSelector:@selector(allTargets)])
	{
		[outputString appendString:@"\n  ** Targets & Actions **\n"];
		UIControl *control = (UIControl *)self.currentView;
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

#pragma mark Keyboard Capture

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if ([string isEqualToString:kDCIntrospectKeysInvoke])
	{
		[self introspectorInvoked:nil];
		return NO;
	}

	if (!self.on)
	{
		return NO;
	}

	if ([string isEqualToString:kDCIntrospectKeysShowViewOutlines])
	{
		[self toggleOutlines];
		return NO;
	}
	else if ([string isEqualToString:kDCIntrospectKeysShowNonOpaqueViews])
	{
		[self toggleOpaqueViews];
		return NO;
	}
	else if ([string isEqualToString:kDCIntrospectKeysFlashViewRedraws])
	{
		[self toggleRedrawFlashing];
		return NO;
	}
	else if ([string isEqualToString:kDCIntrospectKeysToggleShowCoordinates])
	{
		self.frameView.touchPointLabel.alpha = !self.frameView.touchPointLabel.alpha;
	}

	if (self.on && self.currentView)
	{
		if ([string isEqualToString:kDCIntrospectKeysLogProperties])
		{
			[self logPropertiesForCurrentView];
			return NO;
		}
		else if ([string isEqualToString:kDCIntrospectKeysLogViewRecursive])
		{
			[self logRecursiveDescriptionForCurrentView];
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
			[self forceReload];
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
		else if ([string isEqualToString:kDCIntrospectKeysSelectMoveUpViewHeirachy])
		{
			self.currentView = self.currentView.superview;
			[self updateFrameView];
			[self updateStatusBar];
			[self updateToolbar];
			return NO;
		}

		self.currentView.frame = CGRectMake(floorf(frame.origin.x),
											floorf(frame.origin.y),
											floorf(frame.size.width),
											floorf(frame.size.height));
	}

	[self updateFrameView];
	[self updateStatusBar];

	return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSMutableString *outputString = [[[NSMutableString alloc] init] autorelease];
	if (!CGRectEqualToRect(self.originalFrame, self.currentView.frame))
	{
		[outputString appendFormat:@"<#view#>.frame = CGRectMake(%.0f, %.0f, %.0f, %.0f);\n", self.currentView.frame.origin.x, self.currentView.frame.origin.y, self.currentView.frame.size.width, self.currentView.frame.size.height];
	}

	if (self.originalAlpha != self.currentView.alpha)
	{
		[outputString appendFormat:@"<#view#>.alpha = %.2f;\n", self.currentView.alpha];
	}
	
	printf("\n\n%s\n\n", [outputString cStringUsingEncoding:1]);

	return YES;
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
//			if (view.superview == [self mainWindow])
//				newTouchPoint.y += [[UIApplication sharedApplication] statusBarFrame].size.height;
//			if (view != [subview superview])
//			{
//				newTouchPoint.x -= subview.frame.origin.x;
//				newTouchPoint.y -= subview.frame.origin.y;
//			}

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


@end
