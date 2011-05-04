//
//  DCIntrospectDemo
//
//  Created by Domestic Cat on 29/04/11.
//

#import "DCIntrospectDemoAppDelegate.h"
#import "DCIntrospectDemoViewController.h"
#import "DCIntrospect.h"

@implementation DCIntrospectDemoAppDelegate

@synthesize window;
@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	UITapGestureRecognizer *defaultGestureRecognizer = [[[UITapGestureRecognizer alloc] init] autorelease];
	defaultGestureRecognizer.cancelsTouchesInView = NO;
	defaultGestureRecognizer.delaysTouchesBegan = NO;
	defaultGestureRecognizer.delaysTouchesEnded = NO;
	defaultGestureRecognizer.numberOfTapsRequired = 3;
	defaultGestureRecognizer.numberOfTouchesRequired = 2;
	[DCIntrospect sharedIntrospector].gestureRecognizer = defaultGestureRecognizer;

	self.window.rootViewController = self.viewController;
	[self.window makeKeyAndVisible];

	// insert this AFTER makeKeyAndVisible so statusBarOrientation is reported correctly.
	[[DCIntrospect sharedIntrospector] setup];

	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

- (void)dealloc
{
	[window release];
	[viewController release];
	[super dealloc];
}

@end
