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
	self.window.rootViewController = self.viewController;
	[self.window makeKeyAndVisible];
	
	[[DCIntrospect sharedIntrospector] start];
	[[DCIntrospect sharedIntrospector] setOn:YES];
	[[DCIntrospect sharedIntrospector] touchAtPoint:CGPointMake(121, 89)];

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
