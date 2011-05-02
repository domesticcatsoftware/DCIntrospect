//
//  DCIntrospect
//
//  Created by Domestic Cat on 29/04/11.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "DCIntrospectDefines.h"
#import "DCFrameView.h"
#import "DCStatusBarOverlay.h"

@interface DCIntrospect : NSObject <DCFrameViewDelegate, UITextFieldDelegate>
{

}

@property (nonatomic) BOOL on;
@property (nonatomic) BOOL outlinesOn;
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

- (void)introspectorInvoked:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateFrameView;
- (void)updateStatusBar;
- (void)touchAtPoint:(CGPoint)point;

///////////
// Tools //
///////////

- (void)toggleTools;
- (void)logDescriptionForCurrentView;
- (void)toggleOutlines:(id)sender;
- (void)addOutlinesToFrameViewFromSubview:(UIView *)view;

////////////////////
// Helper Methods //
////////////////////

- (UIWindow *)mainWindow;
- (NSMutableArray *)viewsAtPoint:(CGPoint)touchPoint inView:(UIView *)view;
- (void)fadeView:(UIView *)view toAlpha:(CGFloat)alpha;

// Unused/experimental

- (void)describePropertiesForCurrentView;
- (NSString *)prettyDescriptionForProperty:(NSString *)propertyName value:(int)value;
- (BOOL)ignoreView:(UIView *)view;

@end
