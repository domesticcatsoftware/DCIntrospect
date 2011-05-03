//
//  DCIntrospectDemoViewController.m
//  DCIntrospectDemo
//
//  Created by Domestic Cat on 29/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DCIntrospectDemoViewController.h"

@implementation DCIntrospectDemoViewController
@synthesize activityIndicator;
@synthesize label;

- (void)dealloc
{
    [activityIndicator release];
	[label release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.activityIndicator.frame = CGRectOffset(self.activityIndicator.frame, 0.5, 0.0);
}

- (void)viewDidUnload
{
    [self setActivityIndicator:nil];
	[self setLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (IBAction)sliderDidChange:(id)sender {
}

- (IBAction)switchDidChange:(id)sender {
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

@end
