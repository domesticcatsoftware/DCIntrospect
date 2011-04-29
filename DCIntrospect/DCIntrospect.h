//
//  DCIntrospect
//
//  Created by Domestic Cat on 29/04/11.
//

#import <UIKit/UIKit.h>
#import "DCFrameView.h"
#import <QuartzCore/QuartzCore.h>

@interface DCIntrospect : NSObject
{

}

@property (nonatomic, retain) DCFrameView *frameView;
@property (nonatomic, assign) UIView *currentView;

+ (DCIntrospect *)sharedIntrospector;
- (void)start;

//////////////////
// Introspector //
//////////////////

- (void)introspectorInvoked:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateFrameView;

////////////////////
// Helper Methods //
////////////////////

- (UIWindow *)mainWindow;
- (NSMutableArray *)findViewsAtPoint:(CGPoint)touchPoint inView:(UIView *)view addToArray:(NSMutableArray *)views;

@end
