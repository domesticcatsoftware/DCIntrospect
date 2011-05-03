//
//  DCIntrospectDemoViewController.h
//  DCIntrospectDemo
//
//  Created by Domestic Cat on 29/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DCIntrospectDemoViewController : UIViewController <UITextFieldDelegate> {
    
	UIActivityIndicatorView *activityIndicator;
}
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)sliderDidChange:(id)sender;
- (IBAction)switchDidChange:(id)sender;

@end
