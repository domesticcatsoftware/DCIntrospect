//
//  DCIntrospectDemoViewController.h
//  DCIntrospectDemo
//
//  Created by Domestic Cat on 29/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomDrawnView.h"

@interface DCIntrospectDemoViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
{
	UIActivityIndicatorView *activityIndicator;
	UILabel *label;
	CustomDrawnView *customDrawnView;
}

@property (nonatomic, retain) IBOutlet CustomDrawnView *customDrawnView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UILabel *label;

- (IBAction)sliderDidChange:(id)sender;
- (IBAction)switchDidChange:(id)sender;
- (IBAction)removeAllObjectNames:(id)sender;

@end
