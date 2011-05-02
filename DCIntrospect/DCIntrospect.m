//
//  DCIntrospect
//
//  Created by Domestic Cat on 29/04/11.
//

#import "DCIntrospect.h"

DCIntrospect *sharedInstance = nil;

@implementation DCIntrospect
@synthesize on;
@synthesize outlinesOn;
@synthesize statusBarOverlay;
@synthesize inputField;
@synthesize toolbar;
@synthesize frameView;

@synthesize currentView;
@synthesize originalFrame, originalAlpha;

+ (DCIntrospect *)sharedIntrospector
{
	if (!sharedInstance)
	{
		sharedInstance = [[DCIntrospect alloc] init];
	}

	return sharedInstance;
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

	UITapGestureRecognizer *mainGestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(introspectorInvoked:)] autorelease];
	mainGestureRecognizer.cancelsTouchesInView = NO;
	mainGestureRecognizer.delaysTouchesBegan = NO;
	mainGestureRecognizer.delaysTouchesEnded = NO;
	mainGestureRecognizer.numberOfTapsRequired = 2;
	mainGestureRecognizer.numberOfTouchesRequired = 1;
	[mainWindow addGestureRecognizer:mainGestureRecognizer];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleTools) name:kDCIntrospectNotificationShowTools object:nil];

	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatusBarFrame) name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma Introspector

- (void)setOn:(BOOL)newOn
{
	on = newOn;
	[self updateFrameView];
	if (!on)
		self.toolbar.alpha = 0;
}

- (void)introspectorInvoked:(UIGestureRecognizer *)gestureRecognizer
{
	CGPoint touchPoint = [gestureRecognizer locationInView:nil];
	[self touchAtPoint:touchPoint];
	self.on = !self.on;

	if (self.on)
		[self.inputField becomeFirstResponder];
	else
		[self.inputField resignFirstResponder];
}

- (void)updateFrameView
{
	UIWindow *mainWindow = [self mainWindow];
	if (!self.frameView)
	{
		self.frameView = [[[DCFrameView alloc] initWithFrame:(CGRect){ CGPointZero, mainWindow.frame.size } delegate:self] autorelease];
		self.frameView.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.1];
		[mainWindow addSubview:self.frameView];
		self.frameView.alpha = 0.0;
		[self updateStatusBarFrame];
	}

	[mainWindow bringSubviewToFront:self.frameView];
	[mainWindow bringSubviewToFront:self.toolbar];

	if (self.on)
	{
		self.frameView.mainRect = [self.currentView.superview convertRect:self.currentView.frame toView:self.frameView];
		self.frameView.superRect = [self.currentView.superview.superview convertRect:self.currentView.superview.frame toView:self.frameView];
		[self fadeView:self.frameView toAlpha:1.0];
	}
	else
	{
		self.statusBarOverlay.hidden = YES;
		[self fadeView:self.frameView toAlpha:0.0];
	}
}

- (void)updateStatusBar
{
	if (self.currentView.tag != 0)
		self.statusBarOverlay.leftLabel.text = [NSString stringWithFormat:@"%@ (tag: %i)", [self.currentView class], self.currentView.tag];
	else
		self.statusBarOverlay.leftLabel.text = [NSString stringWithFormat:@"%@", [self.currentView class]];

	self.statusBarOverlay.rightLabel.text = NSStringFromCGRect(self.currentView.frame);
	self.statusBarOverlay.hidden = NO;
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
		self.frameView.frame = CGRectMake(0, statusBarSize.height, screenWidth, screenHeight);
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

	[self updateFrameView];
}

- (void)touchAtPoint:(CGPoint)point
{
	NSMutableArray *views = [[NSMutableArray new] autorelease];
	[views addObjectsFromArray:[self viewsAtPoint:point inView:[self mainWindow]]];
	if (views.count == 0)
		return;

	UIView *newView = [views lastObject];
	if (newView != self.currentView)
	{
		if (self.frameView.rectsToOutline.count > 0)
		{
			[self.frameView.rectsToOutline removeAllObjects];
			[self.frameView setNeedsDisplay];
			self.outlinesOn = NO;
		}

		self.currentView = [views lastObject];
		self.originalFrame = self.currentView.frame;
		self.originalAlpha = self.currentView.alpha;
		[self updateFrameView];
		[self updateStatusBar];
	}
}

#pragma Tools

- (void)toggleTools
{
	UIWindow *mainWindow = [self mainWindow];
	if (!self.toolbar)
	{
		CGRect rect = CGRectMake(0.0, [UIApplication sharedApplication].statusBarFrame.size.height, mainWindow.frame.size.width, 30.0);
		self.toolbar = [[[UIScrollView alloc] initWithFrame:rect] autorelease];
		self.toolbar.backgroundColor = [UIColor blackColor];
		self.toolbar.alpha = 0.0;
		[mainWindow addSubview:self.toolbar];

		[self updateStatusBarFrame];
	}

	// setup toolbar
	[self.toolbar.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[(UIView *)obj removeFromSuperview];
	}];

	NSMutableArray *buttons = [[NSMutableArray new] autorelease];
	
	UIButton *logDescriptionButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[logDescriptionButton setTitle:@"recursive desc." forState:UIControlStateNormal];
	[logDescriptionButton addTarget:self action:@selector(logDescriptionForCurrentView) forControlEvents:UIControlEventTouchUpInside];
	[buttons addObject:logDescriptionButton];
	
	UIButton *forceSetNeedsDisplay = [UIButton buttonWithType:UIButtonTypeCustom];
	[forceSetNeedsDisplay setTitle:@"setNeedsDisplay" forState:UIControlStateNormal];
	[forceSetNeedsDisplay addTarget:self action:@selector(forceSetNeedsDisplay) forControlEvents:UIControlEventTouchUpInside];
	[buttons addObject:forceSetNeedsDisplay];
	
	UIButton *forceSetNeedsLayout = [UIButton buttonWithType:UIButtonTypeCustom];
	[forceSetNeedsLayout setTitle:@"setNeedsLayout" forState:UIControlStateNormal];
	[forceSetNeedsLayout addTarget:self action:@selector(forceSetNeedsLayout) forControlEvents:UIControlEventTouchUpInside];
	[buttons addObject:forceSetNeedsLayout];

	if ([self.currentView class] == [UITableView class])
	{
		UIButton *reloadTableView = [UIButton buttonWithType:UIButtonTypeCustom];
		[reloadTableView setTitle:@"reloadData" forState:UIControlStateNormal];
		[reloadTableView addTarget:self action:@selector(forceReloadTableView) forControlEvents:UIControlEventTouchUpInside];
		[buttons addObject:reloadTableView];
	}

	UIButton *autoResizingMask = [UIButton buttonWithType:UIButtonTypeCustom];
	[autoResizingMask setTitle:@"autoresizing" forState:UIControlStateNormal];
	[autoResizingMask addTarget:self action:@selector(editAutoresizingMask) forControlEvents:UIControlEventTouchUpInside];
	[buttons addObject:autoResizingMask];
	

	UIButton *showOutlines = [UIButton buttonWithType:UIButtonTypeCustom];
	[showOutlines setTitle:@"outline views" forState:UIControlStateNormal];
	[showOutlines addTarget:self action:@selector(toggleOutlines:) forControlEvents:UIControlEventTouchUpInside];
	[buttons addObject:showOutlines];
	
	CGFloat x = 0;
	for (UIButton *button in buttons)
	{
		button.titleLabel.font = [UIFont systemFontOfSize:12.0];
		button.titleLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
		[button setTitleColor:[UIColor colorWithWhite:0.78 alpha:1.0] forState:UIControlStateNormal];
		[button setTitleColor:[UIColor colorWithWhite:1.0 alpha:1.0] forState:UIControlStateHighlighted];
		CGSize titleSize = [button.titleLabel.text sizeWithFont:button.titleLabel.font];
		button.frame = CGRectMake(x, 0.0, titleSize.width + 10.0, 24.0);
//		button.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
		[self.toolbar addSubview:button];
		x += button.frame.size.width;
	}

	self.toolbar.contentSize = CGSizeMake(x, self.toolbar.frame.size.height);
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

- (void)logDescriptionForCurrentView
{
	NSLog(@"%@", [self.currentView recursiveDescription]);
}

- (void)forceSetNeedsDisplay
{
	[self.currentView setNeedsDisplay];
}

- (void)forceSetNeedsLayout
{
	[self.currentView setNeedsLayout];
}

- (void)forceReloadTableView
{
	[(UITableView *)self.currentView reloadData];
}

- (void)editAutoresizingMask
{
	// setup toolbar
	[self.toolbar.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[(UIView *)obj removeFromSuperview];
	}];

	UIViewAutoresizing autoresizing = self.currentView.autoresizingMask;
	UIColor *darkerColor = [UIColor colorWithWhite:0.78 alpha:1.0];
	UIColor *whiteColor = [UIColor whiteColor];
	NSMutableArray *buttons = [[NSMutableArray new] autorelease];

	UIButton *flexibleHeightButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[flexibleHeightButton setTitle:@"flexibleWidth" forState:UIControlStateNormal];
	flexibleHeightButton.tag = UIViewAutoresizingFlexibleWidth;
	[flexibleHeightButton addTarget:self action:@selector(autoresizingMaskChanged:) forControlEvents:UIControlEventTouchUpInside];
	[buttons addObject:flexibleHeightButton];

	UIButton *flexibleWidthButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[flexibleWidthButton setTitle:@"flexibleHeight" forState:UIControlStateNormal];
	flexibleWidthButton.tag = UIViewAutoresizingFlexibleHeight;
	[flexibleWidthButton addTarget:self action:@selector(autoresizingMaskChanged:) forControlEvents:UIControlEventTouchUpInside];
	[buttons addObject:flexibleWidthButton];

	UIButton *flexibleLeftMarginButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[flexibleLeftMarginButton setTitle:@"flexibleLeftMargin" forState:UIControlStateNormal];
	flexibleLeftMarginButton.tag = UIViewAutoresizingFlexibleLeftMargin;
	[flexibleLeftMarginButton addTarget:self action:@selector(autoresizingMaskChanged:) forControlEvents:UIControlEventTouchUpInside];
	[buttons addObject:flexibleLeftMarginButton];

	CGFloat x = 0;
	for (UIButton *button in buttons)
	{
		button.titleLabel.font = [UIFont systemFontOfSize:12.0];
		button.titleLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
		[button setTitleColor:(autoresizing & button.tag) ? whiteColor : darkerColor forState:UIControlStateNormal];
		[button setTitleColor:[UIColor colorWithWhite:1.0 alpha:1.0] forState:UIControlStateHighlighted];
		CGSize titleSize = [button.titleLabel.text sizeWithFont:button.titleLabel.font];
		button.frame = CGRectMake(x, 0.0, titleSize.width + 10.0, 24.0);
		[self.toolbar addSubview:button];
		x += button.frame.size.width;
	}

	self.toolbar.contentSize = CGSizeMake(x, self.toolbar.frame.size.height);
}

- (void)autoresizingMaskChanged:(id)sender
{
	NSLog(@"flexibleWidth %i", self.currentView.autoresizingMask & UIViewAutoresizingFlexibleWidth);
	UIButton *button = (UIButton *)sender;
	UIViewAutoresizing originalMask = self.currentView.autoresizingMask;
	UIViewAutoresizing mask = button.tag;
	if (originalMask & mask)
		originalMask = (originalMask &= ~mask);
	else
		originalMask = (originalMask |= mask);
	self.currentView.autoresizingMask = originalMask;
	NSLog(@"after flexibleWidth %i", self.currentView.autoresizingMask & UIViewAutoresizingFlexibleWidth);
	[self.currentView.superview setNeedsLayout];
}

- (void)toggleOutlines:(id)sender
{
	UIButton *toggleOutlinesButton = (UIButton *)sender;
	UIWindow *mainWindow = [self mainWindow];
	self.outlinesOn = !self.outlinesOn;
	[toggleOutlinesButton setTitleColor:(self.outlinesOn) ? [UIColor whiteColor] : [UIColor colorWithWhite:0.8 alpha:1.0]
							   forState:UIControlStateNormal];

	if (self.outlinesOn)
		[self addOutlinesToFrameViewFromSubview:mainWindow];
	else
		[self.frameView.rectsToOutline removeAllObjects];

	[self.frameView setNeedsDisplay];
}

- (void)addOutlinesToFrameViewFromSubview:(UIView *)view
{
	UIWindow *mainWindow = [self mainWindow];
	for (UIView *subview in view.subviews)
	{
		if (subview == self.toolbar || subview == self.frameView)
			continue;

		CGRect rect = [subview.superview convertRect:subview.frame toView:mainWindow];

		NSValue *rectValue = [NSValue valueWithCGRect:rect];
		[self.frameView.rectsToOutline addObject:rectValue];
		[self addOutlinesToFrameViewFromSubview:subview];
	}
}

#pragma Keyboard Capture

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if (self.currentView)
	{
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
		self.currentView.frame = frame;
	}

	[self updateFrameView];
	[self updateStatusBar];

	return YES;
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

#pragma Helper Methods

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
//	touchPoint = [frameView convertPoint:touchPoint toView:[self mainWindow]];
//	touchPoint = CGPointApplyAffineTransform(touchPoint, frameView.transform);
	for (UIView *subview in view.subviews)
	{
		CGRect rect = subview.frame;
		NSLog(@"Point: %@ in Looking in view %@", NSStringFromCGPoint(touchPoint), [view class]);
		if ([self ignoreView:subview])
			continue;

		if (CGRectContainsPoint(rect, touchPoint))
		{
			[views addObject:subview];

			// convert the point to differing transforms as needed
			CGPoint newTouchPoint = touchPoint;
			if (view != [self mainWindow])
			{
				newTouchPoint.x -= subview.frame.origin.x;
				newTouchPoint.y -= subview.frame.origin.y;
			}
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

#pragma Unused/Experimental

- (void)describePropertiesForCurrentView
{
	Class currentViewClass = nil;
	
	NSString *className = [NSString stringWithFormat:@"%@", [self.currentView class]];
	if ([className isEqualToString:@"UIRoundedRectButton"])
		currentViewClass = [UIButton class];
	else
		currentViewClass = [self.currentView class];
	
	unsigned int count;
	Method *methods = class_copyPropertyList(currentViewClass, &count);
    size_t buf_size = 1024;
    char *buffer = malloc(buf_size);
	
	for (unsigned int i = 0; i < count; ++i)
	{
		NSLog(@"%i of %i", i, count);
		// get the property name and selector name
		NSString *propertyName = [NSString stringWithCString:sel_getName(method_getName(methods[i])) encoding:NSUTF8StringEncoding];
		NSString *selectorName = [NSString stringWithCString:sel_getName(method_getName(methods[i])) encoding:NSUTF8StringEncoding];
		//		NSLog(@"%i", propertyName.length);
		//		NSLog(@"%@", propertyName);
		
		// get the return object and type for the selector
		SEL sel = NSSelectorFromString(selectorName);
		Method method = class_getInstanceMethod([self.currentView class], sel);
		id returnObject = ([self.currentView respondsToSelector:sel]) ? [self.currentView performSelector:sel] : nil;
		method_getReturnType(method, buffer, buf_size);
		NSString *returnType = [NSString stringWithFormat:@"%s", buffer];
		
		// print out the return for each value depending on type
		if ([returnType isEqualToString:@"f"])
		{
			NSLog(@"%@: %f", propertyName, returnObject);
		}
		else if ([returnType isEqualToString:@"i"])
		{
			NSString *prettyDescription = [self prettyDescriptionForProperty:propertyName value:returnObject];
			if (prettyDescription)
				NSLog(@"%@: %@", propertyName, prettyDescription);
			else
				NSLog(@"%@: %i", propertyName, returnObject);
		}
		else if ([returnType isEqualToString:@"c"])
		{
			NSLog(@"%@: %@", propertyName, (returnObject) ? @"YES" : @"NO");
		}
		else if ([returnType isEqualToString:@"@"])
		{
			id returnObject = [self.currentView performSelector:sel];
			if ([NSStringFromClass([returnObject class]) isEqualToString:@"UIDeviceRGBColor"])
			{
				UIColor *color = (UIColor *)returnObject;
				if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelRGB)
				{
					const CGFloat *components = CGColorGetComponents(color.CGColor);
					NSLog(@"%@: R: %.0f G: %.0f B: %.0f A: %.2f",
						  propertyName,
						  components[0] * 256,
						  components[1] * 256,
						  components[2] * 256,
						  components[3]);
				}
				else
				{
					NSLog(@"%@: %@ (incompatible color space)", propertyName, returnObject);
				}
			}
			else if ([NSStringFromClass([returnObject class]) isEqualToString:@"UICFFont"])
			{
				UIFont *font = (UIFont *)returnObject;
				NSLog(@"%.0fpx %@", font.pointSize, font.fontName);
			}
			else
			{
				NSLog(@"%@: %@", propertyName, returnObject);
			}
		}
		else if ([returnType isEqualToString:@"{CGSize=ff}"])
		{
			NSValue *value = (NSValue *)returnObject;
			CGSize size = [value CGSizeValue];
			NSLog(@"%@: %@", propertyName, NSStringFromCGSize(size));
		}
		else if ([returnType isEqualToString:@"{UIEdgeInsets=ffff}"])
		{
			NSValue *value = (NSValue *)returnObject;
			UIEdgeInsets insets = [value UIEdgeInsetsValue];
			NSLog(@"%@: %@", propertyName, NSStringFromUIEdgeInsets(insets));
			continue;
		}
		else if (returnType.length == 0)
		{
			// some properties have different getter names, often starting with is (for example: UILabel highlighed)
			// attempt to find the selector name
			NSString *newSelectorName = [NSString stringWithFormat:@"is%@%@", [[selectorName substringToIndex:1] uppercaseString], [selectorName substringFromIndex:1]];
			sel = NSSelectorFromString(newSelectorName);
			if ([self.currentView respondsToSelector:sel])
			{
				if ([self.currentView performSelector:sel])
					NSLog(@"%@: YES", propertyName);
				else
					NSLog(@"%@: NO", propertyName);
			}
			else
			{
				NSLog(@"%@: (Unknown Type)", propertyName);
			}
		}
		else
		{
			NSLog(@"%@", propertyName);
			//			NSLog(@"%@: (Unknown Type: %@)", propertyName, returnType);
		}
	}
	
	free(methods);
    free(buffer);
}

- (NSString *)prettyDescriptionForProperty:(NSString *)propertyName value:(int)value
{
	if ([propertyName isEqualToString:@"textAlignment"])
	{
		switch (value)
		{
			case 0: return @"UITextAlignmentLeft";
			case 1: return @"UITextAlignmentCenter";
			default: return @"UITextAlignmentRight";
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
			default: return @"UILineBreakModeMiddleTruncation";
		}
		
	}
	return nil;
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

@end
