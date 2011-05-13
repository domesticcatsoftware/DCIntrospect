//
//  DCIntrospectDemoViewController.m
//  DCIntrospectDemo
//
//  Created by Domestic Cat on 29/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DCIntrospectDemoViewController.h"
#import "DCIntrospect.h"

@implementation DCIntrospectDemoViewController
@synthesize customDrawnView;
@synthesize activityIndicator;
@synthesize label;

- (void)dealloc
{
	[[DCIntrospect sharedIntrospector] removeNamesForViewsInView:self.view];

    [activityIndicator release];
	[label release];
	[customDrawnView release];
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
	[[DCIntrospect sharedIntrospector] setName:@"activityIndicator" forObject:self.activityIndicator accessedWithSelf:YES];
}

- (void)viewDidUnload
{
    [self setActivityIndicator:nil];
	[self setLabel:nil];
	[self setCustomDrawnView:nil];
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (IBAction)sliderDidChange:(id)sender
{
	[self.customDrawnView setNeedsDisplay];
}

- (IBAction)switchDidChange:(id)sender {
}

- (IBAction)removeAllObjectNames:(id)sender
{
	[[DCIntrospect sharedIntrospector] removeNamesForViewsInView:self.view];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

#pragma mark Table View Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";

	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	cell.accessoryType = UITableViewCellAccessoryCheckmark;
	cell.textLabel.text = @"Text";
	cell.detailTextLabel.text = @"Detailed Text";
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Title";
}

@end
