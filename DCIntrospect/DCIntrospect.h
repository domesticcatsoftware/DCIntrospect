//
//  DCIntrospect.h
//
//  Created by Domestic Cat on 29/04/11.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "DCIntrospectDefines.h"
#import "DCFrameView.h"
#import "DCStatusBarOverlay.h"

#ifdef DEBUG

@interface UIView (debug)

- (NSString *)recursiveDescription;

@end

#endif

@interface DCIntrospect : NSObject <DCFrameViewDelegate, UITextFieldDelegate>
{

}

@property (nonatomic) BOOL keyboardShortcuts;			// default: YES
@property (nonatomic) BOOL showStatusBarOverlay;		// default: YES
@property (nonatomic, retain) UIGestureRecognizer *gestureRecognizer;

@property (nonatomic) BOOL on;
@property (nonatomic) BOOL viewOutlines;
@property (nonatomic) BOOL highlightOpaqueViews;
@property (nonatomic) BOOL flashOnRedraw;
@property (nonatomic, retain) DCFrameView *frameView;
@property (nonatomic, retain) UIScrollView *toolbar;
@property (nonatomic, retain) UITextField *inputField;
@property (nonatomic, retain) DCStatusBarOverlay *statusBarOverlay;

@property (nonatomic, assign) UIView *currentView;
@property (nonatomic) CGRect originalFrame;
@property (nonatomic) CGFloat originalAlpha;


+ (DCIntrospect *)sharedIntrospector;
- (void)start;

//////////////////
// Introspector //
//////////////////

- (void)introspectorInvoked:(UIGestureRecognizer *)aGestureRecognizer;	// can be manually invoked with nil ([[DCIntrospect sharedIntrospector introspectorInvoked:nil];)
- (void)updateFrameView;
- (void)updateStatusBar;
- (void)updateStatusBarFrame;
- (void)touchAtPoint:(CGPoint)point;
- (void)setGestureRecognizer:(UIGestureRecognizer *)newGestureRecognizer;

///////////
// Tools //
///////////

- (void)statusBarTapped;
- (void)updateToolbar;
- (void)logRecursiveDescriptionForCurrentView;
- (void)forceSetNeedsDisplay;
- (void)forceSetNeedsLayout;
- (void)forceReload;
- (void)toggleOutlines;
- (void)addOutlinesToFrameViewFromSubview:(UIView *)view;
- (void)toggleOpaqueViews;
- (void)setBackgroundColor:(UIColor *)color ofOpaqueViewsInSubview:(UIView *)view;
- (void)toggleRedrawFlashing;
- (void)setRedrawFlash:(BOOL)redrawFlash inViewsInSubview:(UIView *)view;

//////////////////
// Experimental //
//////////////////

- (void)logPropertiesForCurrentView;
- (BOOL)ignoreView:(UIView *)view;
- (NSArray *)subclassesOfClass:(Class)parentClass;

//////////////////////
// Keyboard Capture //
//////////////////////

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

/////////////////////////
// Description Methods //
/////////////////////////

- (NSString *)describeProperty:(NSString *)propertyName value:(int)value;
- (NSString *)describeColor:(UIColor *)color;

/////////////////////////
// DCIntrospector Help //
/////////////////////////

- (void)showHelp;

////////////////////
// Helper Methods //
////////////////////

- (UIWindow *)mainWindow;
- (NSMutableArray *)viewsAtPoint:(CGPoint)touchPoint inView:(UIView *)view;
- (void)fadeView:(UIView *)view toAlpha:(CGFloat)alpha;


@end
