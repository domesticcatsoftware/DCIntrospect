//
//  DCIntrospect.m
//
//  Created by Domestic Cat on 29/04/11.
//

#import "DCIntrospect.h"
#import <dlfcn.h>

#include <assert.h>
#include <stdbool.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysctl.h>
//#import "UIApplication+Introspector.h" // disabled for now, consumes all keyboard events
#import "UIView+Introspector.h"
#import "UIWindow+Introspector.h"
#import "CBIntrospect.h"

#ifdef DEBUG
// break into GDB code complied from following sources: 
// http://blog.timac.org/?p=190, http://developer.apple.com/library/mac/#qa/qa1361/_index.html, http://cocoawithlove.com/2008/03/break-into-debugger.html

// Returns true if the current process is being debugged (either 
// running under the debugger or has a debugger attached post facto).
static bool AmIBeingDebugged(void)
{
	int                 junk;
	int                 mib[4];
	struct kinfo_proc   info;
	size_t              size;

	// Initialize the flags so that, if sysctl fails for some bizarre 
	// reason, we get a predictable result.

	info.kp_proc.p_flag = 0;

	// Initialize mib, which tells sysctl the info we want, in this case
	// we're looking for information about a specific process ID.

	mib[0] = CTL_KERN;
	mib[1] = KERN_PROC;
	mib[2] = KERN_PROC_PID;
	mib[3] = getpid();

	// Call sysctl.

	size = sizeof(info);
	junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
	assert(junk == 0);

	// We're being debugged if the P_TRACED flag is set.

	return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
}

#if TARGET_CPU_ARM
#define DEBUGSTOP(signal) __asm__ __volatile__ ("mov r0, %0\nmov r1, %1\nmov r12, %2\nswi 128\n" : : "r"(getpid ()), "r"(signal), "r"(37) : "r12", "r0", "r1", "cc");
#define DEBUGGER do { int trapSignal = AmIBeingDebugged () ? SIGINT : SIGSTOP; DEBUGSTOP(trapSignal); if (trapSignal == SIGSTOP) { DEBUGSTOP (SIGINT); } } while (false);
#else
#define DEBUGGER do { int trapSignal = AmIBeingDebugged () ? SIGINT : SIGSTOP; __asm__ __volatile__ ("pushl %0\npushl %1\npush $0\nmovl %2, %%eax\nint $0x80\nadd $12, %%esp" : : "g" (trapSignal), "g" (getpid ()), "n" (37) : "eax", "cc"); } while (false);
#endif
#endif

#ifdef DEBUG
#define DCLog(M, ...) NSLog(M, ##__VA_ARGS__)
#else
#define DCLog(M, ...) ({});
#endif

@interface DCIntrospect ()

- (void)takeFirstResponder;

@end

@implementation DCIntrospect
@synthesize keyboardBindingsOn, showStatusBarOverlay, invokeGestureRecognizer;
@synthesize on;
@synthesize handleArrowKeys;
@synthesize viewOutlines, highlightNonOpaqueViews, flashOnRedraw;
@synthesize statusBarOverlay;
@synthesize inputTextView = _inputTextView;
@synthesize frameView;
@synthesize objectNames;
@synthesize currentView, originalFrame, originalAlpha;
@synthesize currentViewHistory;
@synthesize showingHelp;
@synthesize enableShakeToActivate;

#pragma mark Setup

+ (void)load
{
#ifdef DEBUG
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSString *simulatorRoot = [[[NSProcessInfo processInfo] environment] objectForKey:@"IPHONE_SIMULATOR_ROOT"];
    if (simulatorRoot)
    {
        void *AppSupport = dlopen([[simulatorRoot stringByAppendingPathComponent:@"/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport"] fileSystemRepresentation], RTLD_LAZY);
        CFStringRef (*CPCopySharedResourcesPreferencesDomainForDomain)(CFStringRef domain) = (CFStringRef (*)())dlsym(AppSupport, "CPCopySharedResourcesPreferencesDomainForDomain");
        if (CPCopySharedResourcesPreferencesDomainForDomain)
        {
            CFStringRef accessibilityDomain = CPCopySharedResourcesPreferencesDomainForDomain(CFSTR("com.apple.Accessibility"));
            if (accessibilityDomain)
            {
                // This must be done *before* UIApplicationMain, hence +load
                CFPreferencesSetValue(CFSTR("ApplicationAccessibilityEnabled"), kCFBooleanTrue, accessibilityDomain, kCFPreferencesAnyUser, kCFPreferencesAnyHost);
                CFRelease(accessibilityDomain);
            }
        }
    }
    [pool drain];
#endif
}

static void *originalValueForKeyIMPKey = &originalValueForKeyIMPKey;

id UITextInputTraits_valueForKey(id self, SEL _cmd, NSString *key);
id UITextInputTraits_valueForKey(id self, SEL _cmd, NSString *key)
{
	static NSMutableSet *textInputTraitsProperties = nil;
	if (!textInputTraitsProperties)
	{
		textInputTraitsProperties = [[NSMutableSet alloc] init];
		unsigned int count = 0;
		objc_property_t *properties = protocol_copyPropertyList(@protocol(UITextInputTraits), &count);
		for (unsigned int i = 0; i < count; i++)
		{
			objc_property_t property = properties[i];
			NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
			[textInputTraitsProperties addObject:propertyName];
		}
		free(properties);
	}
	
	IMP valueForKey = (IMP)[objc_getAssociatedObject([self class], originalValueForKeyIMPKey) pointerValue];
	if ([textInputTraitsProperties containsObject:key])
	{
		id textInputTraits = valueForKey(self, _cmd, @"textInputTraits");
		return valueForKey(textInputTraits, _cmd, key);
	}
	else
	{
		return valueForKey(self, _cmd, key);
	}
}

// See http://stackoverflow.com/questions/6617472/why-does-valueforkey-on-a-uitextfield-throws-an-exception-for-uitextinputtraits
+ (void)workaroundUITextInputTraitsPropertiesBug
{
	Method valueForKey = class_getInstanceMethod([NSObject class], @selector(valueForKey:));
	const char *valueForKeyTypeEncoding = method_getTypeEncoding(valueForKey);
	
	unsigned int count = 0;
	Class *classes = objc_copyClassList(&count);
	for (unsigned int i = 0; i < count; i++)
	{
		Class class = classes[i];
		if (class_getInstanceMethod(class, NSSelectorFromString(@"textInputTraits")))
		{
			IMP originalValueForKey = class_replaceMethod(class, @selector(valueForKey:), (IMP)UITextInputTraits_valueForKey, valueForKeyTypeEncoding);
			if (!originalValueForKey)
				originalValueForKey = (IMP)[objc_getAssociatedObject([class superclass], originalValueForKeyIMPKey) pointerValue];
			if (!originalValueForKey)
				originalValueForKey = class_getMethodImplementation([class superclass], @selector(valueForKey:));
			
			objc_setAssociatedObject(class, originalValueForKeyIMPKey, [NSValue valueWithPointer:(void *)originalValueForKey], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		}
	}
	free(classes);
}

+ (DCIntrospect *)sharedIntrospector
{
    static DCIntrospect *sharedInstance = nil;
#ifdef DEBUG
	if (!sharedInstance)
	{
		sharedInstance = [[[self class] alloc] init];
        sharedInstance.enableShakeToActivate = YES;
		sharedInstance.keyboardBindingsOn = YES;
		sharedInstance.showStatusBarOverlay = ![UIApplication sharedApplication].statusBarHidden;
		[self workaroundUITextInputTraitsPropertiesBug];
//        [UIApplication replaceCanonicalSendEvent];
        [UIWindow replaceCanonicalSendEvent];
	}
#endif
	return sharedInstance;
}

- (UITextView *)inputTextView
{
    if (_inputTextView == nil)
    {
        _inputTextView = [[[UITextView alloc] initWithFrame:CGRectZero] autorelease];
		_inputTextView.delegate = self;
		_inputTextView.autocorrectionType = UITextAutocorrectionTypeNo;
		_inputTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
		_inputTextView.inputView = [[[UIView alloc] init] autorelease];
		_inputTextView.scrollsToTop = NO;
		[[self mainWindow] addSubview:_inputTextView];
    }
    return _inputTextView;
}

- (void)start
{
	UIWindow *mainWindow = [self mainWindow];
	if (!mainWindow)
	{
		DCLog(@"DCIntrospect: Couldn't setup. No main window?");
		return;
	}
	
	if (!self.statusBarOverlay)
	{
		self.statusBarOverlay = [[[DCStatusBarOverlay alloc] init] autorelease];
	}
	
	if (self.keyboardBindingsOn)
	{
		if (![self.inputTextView becomeFirstResponder])
		{
			[self performSelector:@selector(takeFirstResponder) withObject:nil afterDelay:0.5];
		}
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarTapped) name:kDCIntrospectNotificationStatusBarTapped object:nil];
	
	// reclaim the keyboard after dismissal if it is taken
	[[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification
													  object:nil
													   queue:nil
												  usingBlock:^(NSNotification *notification) {
													  // needs to be done after a delay or else it doesn't work for some reason.
													  if (self.keyboardBindingsOn)
														  [self performSelector:@selector(takeFirstResponder)
																	 withObject:nil
																	 afterDelay:0.1];
												  }];
	
  // dirty hack for UIWebView keyboard problems
  [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification *notification) {
                                                  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(takeFirstResponder) object:nil];
                                                }];

	// listen for device orientation changes to adjust the status bar
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews) name:UIDeviceOrientationDidChangeNotification object:nil];
	
	if (!self.currentViewHistory)
		self.currentViewHistory = [[[NSMutableArray alloc] init] autorelease];
	
	DCLog(@"%@ is setup. %@ to start.", [self class], [kDCIntrospectKeysInvoke isEqualToString:@" "] ? @"Push the space bar" : [NSString stringWithFormat:@"Type '%@'",  kDCIntrospectKeysInvoke]);
}

- (void)takeFirstResponder
{
	if (![self.inputTextView becomeFirstResponder])
		DCLog(@"DCIntrospect: Couldn't reclaim keyboard input.  Is the keyboard used elsewhere?");
}

- (void)resetInputTextView
{
	self.inputTextView.text = @"\n2 4567 9\n";
	self.handleArrowKeys = NO;
	self.inputTextView.selectedRange = NSMakeRange(5, 0);
	self.handleArrowKeys = YES;
}

#pragma mark Custom Setters
- (void)setInvokeGestureRecognizer:(UIGestureRecognizer *)newGestureRecognizer
{
	UIWindow *mainWindow = [self mainWindow];
	[mainWindow removeGestureRecognizer:invokeGestureRecognizer];
	
	[invokeGestureRecognizer release];
	invokeGestureRecognizer = nil;
	invokeGestureRecognizer = [newGestureRecognizer retain];
	[invokeGestureRecognizer addTarget:self action:@selector(invokeIntrospector)];
	[mainWindow addGestureRecognizer:invokeGestureRecognizer];
}

- (void)setKeyboardBindingsOn:(BOOL)areKeyboardBindingsOn
{
	keyboardBindingsOn = areKeyboardBindingsOn;
	if (self.keyboardBindingsOn)
		[self.inputTextView becomeFirstResponder];
	else
		[self.inputTextView resignFirstResponder];
}

#pragma mark Main Actions

- (void)invokeIntrospector
{
	self.on = !self.on;
	
	if (self.on)
	{
        DCLog(@"++ Introspector on");
        
		[self updateViews];
		[self updateStatusBar];
		[self updateFrameView];
		
		if (keyboardBindingsOn)
			[self.inputTextView becomeFirstResponder];
		else
			[self.inputTextView resignFirstResponder];
		
		[self resetInputTextView];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kDCIntrospectNotificationIntrospectionDidStart
															object:nil];
	}
	else
	{
        DCLog(@"++ Introspector off");
        
		if (self.viewOutlines)
			[self toggleOutlines];
		if (self.highlightNonOpaqueViews)
			[self toggleNonOpaqueViews];
		if (self.showingHelp)
			[self toggleHelp];
		
		self.statusBarOverlay.hidden = YES;
		self.frameView.alpha = 0;
        [self selectView:nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kDCIntrospectNotificationIntrospectionDidEnd
															object:nil];
	}
}

- (void)touchAtPoint:(CGPoint)point
{
	// convert the point into the main window
	CGPoint convertedTouchPoint = [[self mainWindow] convertPoint:point fromView:self.frameView];
	
	// find all the views under that point – will be added in order on screen, ie mainWindow will be index 0, main view controller at index 1 etc.
	NSMutableArray *views = [self viewsAtPoint:convertedTouchPoint inView:[self mainWindow]];
	if (views.count == 0)
		return;
	
	// get the topmost view and setup the UI
	[self.currentViewHistory removeAllObjects];
	UIView *newView = [views lastObject];
	[self selectView:newView];
}

- (void)selectView:(UIView *)view
{
    [self onWillDeselectView:self.currentView];
    [self onWillSelectView:view];
	self.currentView = view;
    [self onDidSelectView:view];
    
    if (view == nil)
        return; // nil, if deactivating introspector
    
	self.originalFrame = self.currentView.frame;
	self.originalAlpha = self.currentView.alpha;
	
	if (self.frameView.rectsToOutline.count > 0)
	{
		[self.frameView.rectsToOutline removeAllObjects];
		[self.frameView setNeedsDisplay];
		self.viewOutlines = NO;
	}

	[self updateFrameView];
	[self updateStatusBar];
	
	if (![self.currentViewHistory containsObject:self.currentView])
		[self.currentViewHistory addObject:self.currentView];
    
    // resign then activate/focus to ensure keyboard events are consumed
    [self.inputTextView resignFirstResponder]; // or call in application inactive notification
    [self.inputTextView becomeFirstResponder];
}

- (void)statusBarTapped
{
	if (self.showingHelp)
	{
		[self toggleHelp];
		return;
	}
}

#pragma mark Keyboard Capture

- (void)textViewDidChangeSelection:(UITextView *)textView
{
	if (!(self.on && self.handleArrowKeys))
		return;
	
	NSUInteger selectionLocation = textView.selectedRange.location;
	NSUInteger selectionLength = textView.selectedRange.length;
	BOOL shiftKey = selectionLength != 0;
	BOOL optionKey = selectionLocation % 2 == 1;
	
	CGRect frame = self.currentView.frame;
	if (shiftKey)
	{
		if (selectionLocation == 4 && selectionLength == 1)
			frame.origin.x -= 10.0f;
		else if (selectionLocation == 5 && selectionLength == 1)
			frame.origin.x += 10.0f;
		else if (selectionLocation == 0 && selectionLength == 5)
			frame.origin.y -= 10.0f;
		else if (selectionLocation == 5 && selectionLength == 5)
			frame.origin.y += 10.0f;
	}
	else if (optionKey)
	{
		if (selectionLocation == 7)
			frame.size.width += 1.0f;
		else if (selectionLocation == 3)
			frame.size.width -= 1.0f;
		else if (selectionLocation == 9)
			frame.size.height += 1.0f;
		else if (selectionLocation == 1)
			frame.size.height -= 1.0f;
	}
	else
	{
		if (selectionLocation == 4)
			frame.origin.x -= 1.0f;
		else if (selectionLocation == 6)
			frame.origin.x += 1.0f;
		else if (selectionLocation == 0)
			frame.origin.y -= 1.0f;
		else if (selectionLocation == 10)
			frame.origin.y += 1.0f;
	}
	
	self.currentView.frame = CGRectMake(floorf(frame.origin.x),
										floorf(frame.origin.y),
										floorf(frame.size.width),
										floorf(frame.size.height));
	
	[self updateFrameView];
	[self updateStatusBar];
	
	[self resetInputTextView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string
{
	if ([string isEqualToString:kDCIntrospectKeysDisableForPeriod])
    {
        [self setKeyboardBindingsOn:NO];
        [[self inputTextView] resignFirstResponder];
        DCLog(@"DCIntrospect: Disabled for %.1f seconds", kDCIntrospectTemporaryDisableDuration);
        [self performSelector:@selector(setKeyboardBindingsOn:) withObject:[NSNumber numberWithFloat:YES] afterDelay:kDCIntrospectTemporaryDisableDuration];
        return NO;
    }

	if ([string isEqualToString:kDCIntrospectKeysInvoke])
	{
        // below line needs to be disabled if you are using the UIApplication sendEvents: override
		[self invokeIntrospector];
		return NO;
	}
	
	if (!self.on)
		return NO;
	
	if (self.showingHelp)
	{
		[self toggleHelp];
		return NO;
	}
	
    if ([string isEqualToString:kDCIntrospectKeysToggleViewOutlines])
	{
		[self toggleOutlines];
		return NO;
	}
	else if ([string isEqualToString:kDCIntrospectKeysToggleNonOpaqueViews])
	{
		[self toggleNonOpaqueViews];
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
							 NSString *coordinatesString = [NSString stringWithFormat:@"Coordinates are %@", (self.frameView.touchPointLabel.alpha) ? @"on" : @"off"];
							 if (self.showStatusBarOverlay)
								 [self showTemporaryStringInStatusBar:coordinatesString];
							 else
								 DCLog(@"DCIntrospect: %@", coordinatesString);
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
			[self logPropertiesForView:self.currentView];
			return NO;
		}
		else if ([string isEqualToString:kDCIntrospectKeysLogAccessibilityProperties])
		{
			[self logAccessabilityPropertiesForObject:self.currentView];
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
		else if ([string isEqualToString:kDCIntrospectKeysMoveUpInViewHierarchy])
		{
			if (self.currentView.superview)
			{
				[self selectView:self.currentView.superview];
			}
			else
			{
				DCLog(@"DCIntrospect: At top of view hierarchy.");
				return NO;
			}
			return NO;
		}
		else if ([string isEqualToString:kDCIntrospectKeysMoveBackInViewHierarchy])
		{
			if (self.currentViewHistory.count == 0)
				return NO;
			
			int indexOfCurrentView = [self.currentViewHistory indexOfObject:self.currentView];
			if (indexOfCurrentView == 0)
			{
				DCLog(@"DCIntrospect: At bottom of view history.");
				return NO;
			}
			
			[self selectView:[self.currentViewHistory objectAtIndex:indexOfCurrentView - 1]];
		}
		else if ([string isEqualToString:kDCIntrospectKeysMoveDownToFirstSubview])
		{
			if (self.currentView.subviews.count>0) {
				[self selectView:[self.currentView.subviews objectAtIndex:0]];
			}else{
				DCLog(@"DCIntrospect: No subviews.");
				return NO;
			}
			return NO;
		}
		else if ([string isEqualToString:kDCIntrospectKeysMoveToNextSiblingView])
		{
			NSUInteger currentViewsIndex = [self.currentView.superview.subviews indexOfObject:self.currentView];
			
			if (currentViewsIndex==NSNotFound) {
				DCLog(@"DCIntrospect: BROKEN HIERARCHY.");
			} else if (self.currentView.superview.subviews.count>currentViewsIndex + 1) {
				[self selectView:[self.currentView.superview.subviews objectAtIndex:currentViewsIndex + 1]];
			}else{
				DCLog(@"DCIntrospect: No next sibling views.");
				return NO;
			}
			return NO;
		}
		else if ([string isEqualToString:kDCIntrospectKeysMoveToPrevSiblingView])
		{
			NSUInteger currentViewsIndex = [self.currentView.superview.subviews indexOfObject:self.currentView];
			if (currentViewsIndex==NSNotFound) {
				DCLog(@"DCIntrospect: BROKEN HIERARCHY.");
			} else if (currentViewsIndex!=0) {
				[self selectView:[self.currentView.superview.subviews objectAtIndex:currentViewsIndex - 1]];
			} else {
				DCLog(@"DCIntrospect: No previous sibling views.");
			}
			return NO;
		}
		else if ([string isEqualToString:kDCIntrospectKeysLogCodeForCurrentViewChanges])
		{
			[self logCodeForCurrentViewChanges];
			return NO;
		}
		
		CGRect frame = self.currentView.frame;
		if ([string isEqualToString:kDCIntrospectKeysNudgeViewLeft])
			frame.origin.x -= 1.0f;
		else if ([string isEqualToString:kDCIntrospectKeysNudgeViewRight])
			frame.origin.x += 1.0f;
		else if ([string isEqualToString:kDCIntrospectKeysNudgeViewUp])
			frame.origin.y -= 1.0f;
		else if ([string isEqualToString:kDCIntrospectKeysNudgeViewDown])
			frame.origin.y += 1.0f;
		else if ([string isEqualToString:kDCIntrospectKeysCenterInSuperview])
			frame = CGRectMake(floorf((self.currentView.superview.frame.size.width - frame.size.width) / 2.0f),
							   floorf((self.currentView.superview.frame.size.height - frame.size.height) / 2.0f),
							   frame.size.width,
							   frame.size.height);
		else if ([string isEqualToString:kDCIntrospectKeysIncreaseWidth])
			frame.size.width += 1.0f;
		else if ([string isEqualToString:kDCIntrospectKeysDecreaseWidth])
			frame.size.width -= 1.0f;
		else if ([string isEqualToString:kDCIntrospectKeysIncreaseHeight])
			frame.size.height += 1.0f;
		else if ([string isEqualToString:kDCIntrospectKeysDecreaseHeight])
			frame.size.height -= 1.0f;
		else if ([string isEqualToString:kDCIntrospectKeysIncreaseViewAlpha])
		{
			if (self.currentView.alpha < 1.0f)
				self.currentView.alpha += 0.05f;
		}
		else if ([string isEqualToString:kDCIntrospectKeysDecreaseViewAlpha])
		{
			if (self.currentView.alpha > 0.0f)
				self.currentView.alpha -= 0.05f;
		}
		else if ([string isEqualToString:kDCIntrospectKeysEnterGDB])
		{
#ifdef DEBUG
			UIView *view = self.currentView;
			view.tag = view.tag;	// suppress the xcode warning about an unused variable.
			DCLog(@"DCIntrospect: access current view using local 'view' variable.");
			DEBUGGER;
			return NO;
#endif
		}
		
		self.currentView.frame = CGRectMake(floorf(frame.origin.x),
											floorf(frame.origin.y),
											floorf(frame.size.width),
											floorf(frame.size.height));
		
		[self updateFrameView];
		[self updateStatusBar];
	}
	
	return NO;
}

#pragma mark Object Names

- (void)logCodeForCurrentViewChanges
{
	if (!self.currentView)
		return;
	
	NSString *varName = [self nameForObject:self.currentView];
	if ([varName isEqualToString:[NSString stringWithFormat:@"%@", self.currentView.class]])
		varName = @"<#view#>";
	
	NSMutableString *outputString = [NSMutableString string];
	if (!CGRectEqualToRect(self.originalFrame, self.currentView.frame))
	{
		[outputString appendFormat:@"%@.frame = CGRectMake(%.1f, %.1f, %.1f, %.1f);\n", varName, self.currentView.frame.origin.x, self.currentView.frame.origin.y, self.currentView.frame.size.width, self.currentView.frame.size.height];
	}
	
	if (self.originalAlpha != self.currentView.alpha)
	{
		[outputString appendFormat:@"%@.alpha = %.2f;\n", varName, self.currentView.alpha];
	}
	
	if (outputString.length == 0)
    {
		DCLog(@"DCIntrospect: No changes made to %@.", self.currentView.class);
    }
	else
		printf("\n\n%s\n", [outputString UTF8String]);
}

- (void)setName:(NSString *)name forObject:(id)object accessedWithSelf:(BOOL)accessedWithSelf
{
	if (!self.objectNames)
		self.objectNames = [NSMutableDictionary dictionary];
	
	if (accessedWithSelf)
		name = [@"self." stringByAppendingString:name];
	
	[self.objectNames setValue:object forKey:name];
}

- (NSString *)nameForObject:(id)object
{
	__block NSString *objectName = NSStringFromClass([object class]);
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

#pragma mark Layout

- (void)updateFrameView
{
	UIWindow *mainWindow = [self mainWindow];
	if (!self.frameView)
	{
		self.frameView = [[[DCFrameView alloc] initWithFrame:(CGRect){ CGPointZero, mainWindow.frame.size } delegate:self] autorelease];
		[mainWindow addSubview:self.frameView];
		self.frameView.alpha = 0.0f;
		[self updateViews];
	}
	
	[mainWindow bringSubviewToFront:self.frameView];
	
	if (self.on)
	{
		if (self.currentView)
		{
			self.frameView.mainRect = [self.currentView.superview convertRect:self.currentView.frame toView:self.frameView];
			if (self.currentView.superview == mainWindow)
				self.frameView.superRect = CGRectZero;
			else if (self.currentView.superview.superview)
				self.frameView.superRect = [self.currentView.superview.superview convertRect:self.currentView.superview.frame toView:self.frameView];
			else
				self.frameView.superRect = CGRectZero;
		}
		else
		{
			self.frameView.mainRect = CGRectZero;
		}
		
		[self fadeView:self.frameView toAlpha:1.0f];
	}
	else
	{
		[self fadeView:self.frameView toAlpha:0.0f];
	}
}

- (void)updateStatusBar
{
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
		self.statusBarOverlay.rightLabel.text = [NSString stringWithFormat:@"'%@' for help", kDCIntrospectKeysToggleHelp];
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
	
	CGFloat pi = (CGFloat)M_PI;
	if (orientation == UIDeviceOrientationPortrait)
	{
		self.frameView.transform = CGAffineTransformIdentity;
		self.frameView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
	}
	else if (orientation == UIDeviceOrientationLandscapeLeft)
	{
		self.frameView.transform = CGAffineTransformMakeRotation(pi * (90) / 180.0f);
		self.frameView.frame = CGRectMake(screenWidth - screenHeight, 0, screenHeight, screenHeight);
	}
	else if (orientation == UIDeviceOrientationLandscapeRight)
	{
		self.frameView.transform = CGAffineTransformMakeRotation(pi * (-90) / 180.0f);
		self.frameView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
	}
	else if (orientation == UIDeviceOrientationPortraitUpsideDown)
	{
		self.frameView.transform = CGAffineTransformMakeRotation(pi);
		self.frameView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
	}
	
	self.currentView = nil;
	[self updateFrameView];
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
	// [UIView recursiveDescription] is a private method.  This should probably be re-written to avoid any potential problems.
	DCLog(@"DCIntrospect: %@", [view recursiveDescription]);
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
	if ([self.currentView respondsToSelector:@selector(reloadData)])
		[(id)self.currentView reloadData];
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
	
	NSString *string = [NSString stringWithFormat:@"Showing view outlines is %@", (self.viewOutlines) ? @"on" : @"off"];
	if (self.showStatusBarOverlay)
		[self showTemporaryStringInStatusBar:string];
	else
		DCLog(@"DCIntrospect: %@", string);
}

- (void)addOutlinesToFrameViewFromSubview:(UIView *)view
{
	for (UIView *subview in view.subviews)
	{
		if ([self shouldIgnoreView:subview])
			continue;
		
		CGRect rect = [subview.superview convertRect:subview.frame toView:frameView];
		
		NSValue *rectValue = [NSValue valueWithCGRect:rect];
		[self.frameView.rectsToOutline addObject:rectValue];
		[self addOutlinesToFrameViewFromSubview:subview];
	}
}

- (void)toggleNonOpaqueViews
{
	self.highlightNonOpaqueViews = !self.highlightNonOpaqueViews;
	
	UIWindow *mainWindow = [self mainWindow];
	[self setBackgroundColor:(self.highlightNonOpaqueViews) ? kDCIntrospectOpaqueColor : [UIColor clearColor]
   ofNonOpaqueViewsInSubview:mainWindow];
	
	NSString *string = [NSString stringWithFormat:@"Highlighting non-opaque views is %@", (self.highlightNonOpaqueViews) ? @"on" : @"off"];
	if (self.showStatusBarOverlay)
		[self showTemporaryStringInStatusBar:string];
	else
		DCLog(@"DCIntrospect: %@", string);
}

- (void)setBackgroundColor:(UIColor *)color ofNonOpaqueViewsInSubview:(UIView *)view
{
	for (UIView *subview in view.subviews)
	{
		if ([self shouldIgnoreView:subview])
			continue;
		
		if (!subview.opaque)
			subview.backgroundColor = color;
		
		[self setBackgroundColor:color ofNonOpaqueViewsInSubview:subview];
	}
}

- (void)toggleRedrawFlashing
{
	self.flashOnRedraw = !self.flashOnRedraw;
	NSString *string = [NSString stringWithFormat:@"Flashing on redraw is %@", (self.flashOnRedraw) ? @"on" : @"off"];
	if (self.showStatusBarOverlay)
		[self showTemporaryStringInStatusBar:string];
	else
		DCLog(@"DCIntrospect: %@", string);
	
	// flash all views to show what is working
	[self callDrawRectOnViewsInSubview:[self mainWindow]];
}

- (void)callDrawRectOnViewsInSubview:(UIView *)subview
{
	for (UIView *view in subview.subviews)
	{
		if (![self shouldIgnoreView:view])
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

- (NSString *)describeProperty:(NSString *)propertyName value:(id)value
{
	return [UIView describeProperty:propertyName value:value];
}

#pragma mark DCIntrospector Help

- (void)toggleHelp
{
	UIWindow *mainWindow = [self mainWindow];
	self.showingHelp = !self.showingHelp;
	
	if (self.showingHelp)
	{
		self.statusBarOverlay.leftLabel.text = @"Help";
		self.statusBarOverlay.rightLabel.text = @"Any key to close";
		UIView *backingView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, mainWindow.frame.size.width, mainWindow.frame.size.height)] autorelease];
		backingView.tag = 1548;
		backingView.alpha = 0;
		backingView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.85f];
		[mainWindow addSubview:backingView];
		
		UIWebView *webView = [[[UIWebView alloc] initWithFrame:backingView.frame] autorelease];
		webView.opaque = NO;
		webView.backgroundColor = [UIColor clearColor];
		webView.delegate = self;
		[backingView addSubview:webView];
		
		NSMutableString *helpString = [NSMutableString stringWithString:@"<html>"];
		[helpString appendString:@"<head><style>"];
		[helpString appendString:@"body { background-color:rgba(0, 0, 0, 0.0); font:10pt helvetica; line-height: 15px margin-left:5px; margin-right:5px; margin-top:20px; color:rgb(240, 240, 240); } a { color:#45e0fe; font-weight:bold; } h1 { width:100%; font-size:14pt; border-bottom: 1px solid white; margin-top:22px; } h2 { font-size:11pt; margin-left:3px; margin-bottom:2px; } .name { margin-left:7px; } .key { float:right; margin-right:7px; } .key, .code { font-family:Courier; font-weight:bold; color:#CE8B39; } .spacer { height:10px; } p { margin-left: 7px; margin-right: 7px; }"];
		
		if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
			[helpString appendString:@"body { font-size:11pt; width:500px; margin:0 auto; }"];
		
		[helpString appendString:@"</style></head><body><h1>DCIntrospect</h1>"];
		[helpString appendString:@"<p>Created by <a href='http://domesticcat.com.au'>Domestic Cat Software</a> 2011.</p>"];
		[helpString appendString:@"<p>Twitter: <a href='http://twitter.com/patr'>@patr</a></p>"];
		[helpString appendString:@"<p>More info and full documentation: <a href='http://domesticcat.com.au/projects/introspect'>domesticcat.com.au/projects/introspect</a></p>"];
		[helpString appendString:@"<p>GitHub project: <a href='https://github.com/domesticcatsoftware/dcintrospect'>github.com/domesticcatsoftware/dcintrospect/</a></p>"];
		
		[helpString appendString:@"<div class='bindings'><h1>Key Bindings</h1>"];
		[helpString appendString:@"<p>Edit DCIntrospectSettings.h to change key bindings.</p>"];
		
		[helpString appendString:@"<h2>General</h2>"];
		
		[helpString appendFormat:@"<div><span class='name'>Invoke Introspector</span><div class='key'>%@</div></div>", ([kDCIntrospectKeysInvoke isEqualToString:@" "]) ? @"spacebar" : kDCIntrospectKeysInvoke];
		[helpString appendFormat:@"<div><span class='name'>Toggle View Outlines</span><div class='key'>%@</div></div>", kDCIntrospectKeysToggleViewOutlines];
		[helpString appendFormat:@"<div><span class='name'>Toggle Highlighting Non-Opaque Views</span><div class='key'>%@</div></div>", kDCIntrospectKeysToggleNonOpaqueViews];
		[helpString appendFormat:@"<div><span class='name'>Toggle Help</span><div class='key'>%@</div></div>", kDCIntrospectKeysToggleHelp];
		[helpString appendFormat:@"<div><span class='name'>Toggle flash on <span class='code'>drawRect:</span> (see below)</span><div class='key'>%@</div></div>", kDCIntrospectKeysToggleFlashViewRedraws];
		[helpString appendFormat:@"<div><span class='name'>Toggle coordinates</span><div class='key'>%@</div></div>", kDCIntrospectKeysToggleShowCoordinates];
		[helpString appendString:@"<div class='spacer'></div>"];
		
		[helpString appendString:@"<h2>When a view is selected</h2>"];
		[helpString appendFormat:@"<div><span class='name'>Log Properties</span><div class='key'>%@</div></div>", kDCIntrospectKeysLogProperties];
		[helpString appendFormat:@"<div><span class='name'>Log Accessibility Properties</span><div class='key'>%@</div></div>", kDCIntrospectKeysLogAccessibilityProperties];
		[helpString appendFormat:@"<div><span class='name'>Log Recursive Description for View</span><div class='key'>%@</div></div>", kDCIntrospectKeysLogViewRecursive];
		[helpString appendFormat:@"<div><span class='name'>Enter GDB</span><div class='key'>%@</div></div>", kDCIntrospectKeysEnterGDB];
		[helpString appendFormat:@"<div><span class='name'>Move up in view hierarchy</span><div class='key'>%@</div></div>", ([kDCIntrospectKeysMoveUpInViewHierarchy isEqualToString:@""]) ? @"page up" : kDCIntrospectKeysMoveUpInViewHierarchy];
		[helpString appendFormat:@"<div><span class='name'>Move back down in view hierarchy</span><div class='key'>%@</div></div>", ([kDCIntrospectKeysMoveBackInViewHierarchy isEqualToString:@""]) ? @"page down" : kDCIntrospectKeysMoveBackInViewHierarchy];
		[helpString appendString:@"<div class='spacer'></div>"];
		
		[helpString appendFormat:@"<div><span class='name'>Nudge Left</span><div class='key'>\uE235 / %@</div></div>", kDCIntrospectKeysNudgeViewLeft];
		[helpString appendFormat:@"<div><span class='name'>Nudge Right</span><div class='key'>\uE234 / %@</div></div>", kDCIntrospectKeysNudgeViewRight];
		[helpString appendFormat:@"<div><span class='name'>Nudge Up</span><div class='key'>\uE232 / %@</div></div>", kDCIntrospectKeysNudgeViewUp];
		[helpString appendFormat:@"<div><span class='name'>Nudge Down</span><div class='key'>\uE233 / %@</div></div>", kDCIntrospectKeysNudgeViewDown];
		[helpString appendFormat:@"<div><span class='name'>Center in Superview</span><div class='key'>%@</div></div>", kDCIntrospectKeysCenterInSuperview];
		[helpString appendFormat:@"<div><span class='name'>Increase Width</span><div class='key'>alt + \uE234 / %@</div></div>", kDCIntrospectKeysIncreaseWidth];
		[helpString appendFormat:@"<div><span class='name'>Decrease Width</span><div class='key'>alt + \uE235 / %@</div></div>", kDCIntrospectKeysDecreaseWidth];
		[helpString appendFormat:@"<div><span class='name'>Increase Height</span><div class='key'>alt + \uE233 / %@</div></div>", kDCIntrospectKeysIncreaseHeight];
		[helpString appendFormat:@"<div><span class='name'>Decrease Height</span><div class='key'>alt + \uE232 / %@</div></div>", kDCIntrospectKeysDecreaseHeight];
		[helpString appendFormat:@"<div><span class='name'>Increase Alpha</span><div class='key'>%@</div></div>", kDCIntrospectKeysIncreaseViewAlpha];
		[helpString appendFormat:@"<div><span class='name'>Decrease Alpha</span><div class='key'>%@</div></div>", kDCIntrospectKeysDecreaseViewAlpha];
		[helpString appendFormat:@"<div><span class='name'>Log view code</span><div class='key'>%@</div></div>", kDCIntrospectKeysLogCodeForCurrentViewChanges];
		[helpString appendString:@"<div class='spacer'></div>"];
		
		[helpString appendFormat:@"<div><span class='name'>Call setNeedsDisplay</span><div class='key'>%@</div></div>", kDCIntrospectKeysSetNeedsDisplay];
		[helpString appendFormat:@"<div><span class='name'>Call setNeedsLayout</span><div class='key'>%@</div></div>", kDCIntrospectKeysSetNeedsLayout];
		[helpString appendFormat:@"<div><span class='name'>Call reloadData (UITableView only)</span><div class='key'>%@</div></div>", kDCIntrospectKeysReloadData];
		[helpString appendString:@"</div>"];
		
		[helpString appendFormat:@"<h1>GDB</h1><p>Push <span class='code'>%@</span> (backtick) to jump into GDB.  The currently selected view will be available as a variable named 'view'.</p>", kDCIntrospectKeysEnterGDB];
		
		[helpString appendFormat:@"<h1>Flash on <span class='code'>drawRect:</span> calls</h1><p>To implement, call <span class='code'>[[DCIntrospect sharedIntrospector] flashRect:inView:]</span> inside the <span class='code'>drawRect:</span> method of any view you want to track.</p><p>When Flash on <span class='code'>drawRect:</span> is toggled on (binding: <span class='code'>%@</span>) the view will flash whenever <span class='code'>drawRect:</span> is called.</p>", kDCIntrospectKeysToggleFlashViewRedraws];
		
		[helpString appendFormat:@"<h1>Naming objects & logging code</h1><p>By providing names for objects using <span class='code'>setName:forObject:accessedWithSelf:</span>, that name will be shown in the status bar instead of the class of the view.</p><p>This is also used when logging view code (binding: <span class='code'>%@</span>).  Logging view code prints formatted code to the console for properties that have been changed.</p><p>For example, if you resize/move a view using the nudge keys, logging the view code will print <span class='code'>view.frame = CGRectMake(50.0 ..etc);</span> to the console.  If a name is provided then <span class='code'>view</span> is replaced by the name.</p>", kDCIntrospectKeysLogCodeForCurrentViewChanges];
		
		[helpString appendString:@"<h1>License</h1><p>DCIntrospect is made available under the <a href='http://en.wikipedia.org/wiki/MIT_License'>MIT license</a>.</p>"];
		
		[helpString appendString:@"<h2 style='text-align:center;'><a href='http://close'>Close Help</h2>"];
		[helpString appendString:@"<div class='spacer'></div>"];
		
		[UIView animateWithDuration:0.1
						 animations:^{
							 backingView.alpha = 1.0f;
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
	[self logPropertiesForView:self.currentView];
}

- (void)logPropertiesForView:(UIView *)object
{
    NSString *outputString = [object viewDescription];
	DCLog(@"DCIntrospect: %@", outputString);
}

- (void)logAccessabilityPropertiesForObject:(id)object
{
	Class objectClass = [object class];
	NSString *className = [NSString stringWithFormat:@"%@", objectClass];
	NSMutableString *outputString = [NSMutableString string];
	
	// warn about accessibility inspector if the element count is zero
	NSUInteger count = [object accessibilityElementCount];
	if (count == 0)
		[outputString appendString:@"\n\n** Warning: Logging accessibility properties requires Accessibility Inspector: Settings.app -> General -> Accessibility\n"];
	
	[outputString appendFormat:@"** %@ Accessibility Properties **\n", className];
	[outputString appendFormat:@"	label: %@\n", [object accessibilityLabel]];
	[outputString appendFormat:@"	hint: %@\n", [object accessibilityHint]];
	[outputString appendFormat:@"	traits: %@\n", [self describeProperty:@"accessibilityTraits" value:[NSNumber numberWithUnsignedLongLong:[object accessibilityTraits]]]];
	[outputString appendFormat:@"	value: %@\n", [object accessibilityValue]];
	[outputString appendFormat:@"	frame: %@\n", NSStringFromCGRect([object accessibilityFrame])];
	[outputString appendString:@"\n"];
	
	DCLog(@"DCIntrospect: %@", outputString);
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
		if ([self shouldIgnoreView:subview])
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

- (BOOL)shouldIgnoreView:(UIView *)view
{
	if (view == self.frameView || view == self.inputTextView)
		return YES;
	return NO;
}

#pragma mark - Select View Delegate

- (void)onDidSelectView:(UIView *)view
{
    // empty
}

- (void)onWillSelectView:(UIView *)view
{
    // empty
}

- (void)onWillDeselectView:(UIView *)view
{
    // empty
}

@end
