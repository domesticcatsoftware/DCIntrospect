//
//  DCIntrospect.h
//
//  Created by Domestic Cat on 29/04/11.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "DCIntrospectSettings.h"
#import "DCFrameView.h"
#import "DCStatusBarOverlay.h"

#define kDCIntrospectNotificationIntrospectionDidStart @"kDCIntrospectNotificationIntrospectionDidStart"
#define kDCIntrospectNotificationIntrospectionDidEnd @"kDCIntrospectNotificationIntrospectionDidEnd"

typedef void (^Block)();

#ifdef DEBUG

@interface UIView (debug)

- (NSString *)recursiveDescription;

@end

#endif

@interface DCIntrospect : NSObject <DCFrameViewDelegate, UITextFieldDelegate, UIWebViewDelegate>
{
}

@property (nonatomic) BOOL keyboardBindingsOn;							// default: YES
@property (nonatomic) BOOL showStatusBarOverlay;						// default: YES
@property (nonatomic, retain) UIGestureRecognizer *gestureRecognizer;	// default: nil

@property (nonatomic) BOOL on;
@property (nonatomic) BOOL viewOutlines;
@property (nonatomic) BOOL highlightOpaqueViews;
@property (nonatomic) BOOL flashOnRedraw;
@property (nonatomic, retain) DCFrameView *frameView;
@property (nonatomic, retain) UIScrollView *toolbar;
@property (nonatomic, retain) UITextField *inputField;
@property (nonatomic, retain) DCStatusBarOverlay *statusBarOverlay;

@property (nonatomic, retain) NSMutableDictionary *objectNames;

@property (nonatomic, retain) NSMutableArray *blockActions;
@property (nonatomic) BOOL waitingForBlockKey;

@property (nonatomic, assign) UIView *currentView;
@property (nonatomic) CGRect originalFrame;
@property (nonatomic) CGFloat originalAlpha;

@property (nonatomic) BOOL showingHelp;

///////////
// Setup //
///////////

+ (DCIntrospect *)sharedIntrospector;		// this returns nil when DEBUG is not defined.
- (void)setup;								// call setup AFTER makeKeyAndVisible so statusBarOrientation is reported correctly.

////////////////////
// Custom Setters //
////////////////////

- (void)setGestureRecognizer:(UIGestureRecognizer *)newGestureRecognizer;
- (void)setKeyboardBindingsOn:(BOOL)keyboardBindingsOn;

//////////////////
// Main Actions //
//////////////////

- (void)invokeIntrospector;					// can be called manually
- (void)touchAtPoint:(CGPoint)point;		// can be called manually
- (void)statusBarTapped;

//////////////////////
// Keyboard Capture //
//////////////////////

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
- (BOOL)textFieldShouldReturn:(UITextField *)textField;

//////////////////
// Object Names //
//////////////////

// make sure all names that are added are removed at dealloc or else they will be retained here!

- (void)setName:(NSString *)name forObject:(id)object accessDirectly:(BOOL)accessDirectly;
- (NSString *)nameForObject:(id)object;
- (void)removeNamesForViewsInView:(UIView *)view;
- (void)removeNameForObject:(id)object;

////////////
// Blocks //
////////////

- (void)addBlock:(void (^)(void))block withName:(NSString *)name keyBinding:(NSString *)keyBinding;
- (void)enterBlockMode;
- (NSDictionary *)blockForKeyBinding:(NSString *)keyBinding;

////////////
// Layout //
////////////

- (void)updateFrameView;
- (void)updateStatusBar;
- (void)updateViews;
- (void)updateToolbar;
- (void)showTemporaryStringInStatusBar:(NSString *)string;

/////////////
// Actions //
/////////////

- (void)logRecursiveDescriptionForCurrentView;
- (void)logRecursiveDescriptionForView:(UIView *)view;
- (void)forceSetNeedsDisplay;
- (void)forceSetNeedsLayout;
- (void)forceReloadOfView;
- (void)toggleOutlines;
- (void)addOutlinesToFrameViewFromSubview:(UIView *)view;
- (void)toggleOpaqueViews;
- (void)setBackgroundColor:(UIColor *)color ofOpaqueViewsInSubview:(UIView *)view;
- (void)toggleRedrawFlashing;
- (void)callDrawRectOnViewsInSubview:(UIView *)subview;
- (void)flashRect:(CGRect)rect inView:(UIView *)view;

/////////////////////////////
// (Somewhat) Experimental //
/////////////////////////////

- (void)logPropertiesForCurrentView;
- (void)logPropertiesForObject:(id)object;
- (BOOL)ignoreView:(UIView *)view;
- (NSArray *)subclassesOfClass:(Class)parentClass;

/////////////////////////
// Description Methods //
/////////////////////////

- (NSString *)describeProperty:(NSString *)propertyName type:(NSString *)type value:(id)value;
- (NSString *)describeColor:(UIColor *)color;

/////////////////////////
// DCIntrospector Help //
/////////////////////////

- (void)toggleHelp;
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;

////////////////////
// Helper Methods //
////////////////////

- (UIWindow *)mainWindow;
- (NSMutableArray *)viewsAtPoint:(CGPoint)touchPoint inView:(UIView *)view;
- (void)fadeView:(UIView *)view toAlpha:(CGFloat)alpha;
- (BOOL)view:(UIView *)view containsSubview:(UIView *)subview;

@end
