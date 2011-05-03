//
//  DCIntrospectDemoAppDelegate.h
//
//  Created by Domestic Cat on 29/04/11.
//

#import <UIKit/UIKit.h>

@class DCIntrospectDemoViewController;

@interface DCIntrospectDemoAppDelegate : NSObject <UIApplicationDelegate>
{
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet DCIntrospectDemoViewController *viewController;

@end
