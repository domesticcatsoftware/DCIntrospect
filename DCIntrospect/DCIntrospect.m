//
//  DCIntrospect
//
//  Created by Domestic Cat on 29/04/11.
//

#import "DCIntrospect.h"

DCIntrospect *sharedInstance = nil;

@implementation DCIntrospect
@synthesize frameView;
@synthesize currentView;

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

	UITapGestureRecognizer *mainGestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(introspectorInvoked:)] autorelease];
	mainGestureRecognizer.cancelsTouchesInView = NO;
	mainGestureRecognizer.delaysTouchesBegan = NO;
	mainGestureRecognizer.delaysTouchesEnded = NO;
	mainGestureRecognizer.numberOfTapsRequired = 2;
	mainGestureRecognizer.numberOfTouchesRequired = 1;
	[mainWindow addGestureRecognizer:mainGestureRecognizer];
}

#pragma Introspector

- (void)introspectorInvoked:(UIGestureRecognizer *)gestureRecognizer
{
	self.currentView.layer.borderWidth = 0.0;
	CGPoint touchPoint = [gestureRecognizer locationInView:nil];

	NSMutableArray *views = [NSMutableArray new];
	views = [self findViewsAtPoint:touchPoint inView:[self mainWindow] addToArray:views];
	NSLog(@"got back %@", views);
	self.currentView = [views lastObject];
	self.currentView.layer.borderColor = [UIColor blueColor].CGColor;
	self.currentView.layer.borderWidth = 1.0;
	[self updateFrameView];
}

- (void)updateFrameView
{
	UIWindow *mainWindow = [self mainWindow];
	if (!self.frameView)
	{
		NSLog(@"Creating frameview");
		self.frameView = [[[DCFrameView alloc] initWithFrame:(CGRect){ CGPointZero, mainWindow.frame.size }] autorelease];
		[mainWindow addSubview:self.frameView];
	}

	[mainWindow bringSubviewToFront:self.frameView];

	[UIView animateWithDuration:0.1
						  delay:0.0
						options:UIViewAnimationOptionAllowUserInteraction
					 animations:^{
						 self.frameView.alpha = 0.0;
					 }
					 completion:nil];

	self.frameView.mainRect = [self.currentView.superview convertRect:self.currentView.frame toView:self.frameView];
	self.frameView.superRect = [self.currentView.superview.superview convertRect:self.currentView.superview.frame toView:mainWindow];

	[UIView animateWithDuration:0.1
						  delay:0.0
						options:UIViewAnimationOptionAllowUserInteraction
					 animations:^{
						 self.frameView.alpha = 1.0;
					 }
					 completion:nil];
}

////////////////////
// Helper Methods //
////////////////////

- (UIWindow *)mainWindow
{
	NSArray *windows = [[UIApplication sharedApplication] windows];
	if (windows.count == 0)
		return nil;

	return [windows objectAtIndex:0];
}

- (NSMutableArray *)findViewsAtPoint:(CGPoint)touchPoint inView:(UIView *)view addToArray:(NSMutableArray *)views
{
	for (UIView *subview in view.subviews)
	{
		if (subview == self.frameView)
			continue;

		if (CGRectContainsPoint(subview.frame, touchPoint))
		{
			[views addObject:subview];
			views = [self findViewsAtPoint:[subview.superview convertPoint:touchPoint toView:subview] inView:subview addToArray:views];
		}
	}

	return views;
}


@end
