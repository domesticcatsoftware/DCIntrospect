//
//  DCIntrospectDemoViewController.m
//  DCIntrospectDemo
//
//  Created by Domestic Cat on 29/04/11.
//  Copyright 2011 Domestic Cat Software. All rights reserved.
//

#import "DCIntrospectDemoViewController.h"
#import "DCIntrospect.h"

@implementation DCIntrospectDemoViewController
@synthesize activityIndicator;
@synthesize label;

- (void)dealloc
{
	[[DCIntrospect sharedIntrospector] removeNamesForViewsInView:self.view];
    // It is important for the delegate to be set as nil to prevent crashes.
    [DCIntrospect sharedIntrospector].delegate = nil;

    [activityIndicator release];
	[label release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];

    [DCIntrospect sharedIntrospector].delegate = self;
    
	// set the activity indicator to a non-integer frame for demonstration
	self.activityIndicator.frame = CGRectOffset(self.activityIndicator.frame, 0.5, 0.0);
	[[DCIntrospect sharedIntrospector] setName:@"activityIndicator" forObject:self.activityIndicator accessedWithSelf:YES];
}

- (void)viewDidUnload
{
    [self setActivityIndicator:nil];
	[self setLabel:nil];

	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
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
	}

	cell.textLabel.text = [NSString stringWithFormat:@"Row %i", indexPath.row];
	cell.detailTextLabel.text = @"Detailed Text";
	cell.accessoryType = UITableViewCellAccessoryCheckmark;

	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [NSString stringWithFormat:@"Section %i", section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)buttonTapped:(id)sender
{
}

- (IBAction)switchChanged:(id)sender
{
}

- (IBAction)sliderChanged:(id)sender
{
}

#pragma mark - DCIntrospectDelegate methods

- (BOOL)introspect:(DCIntrospect *)theIntrospect shouldConsumeKeyboardInput:(NSString *)theInput {
    if ([theInput isEqualToString:@"z"]) {
        if (self.label.backgroundColor == nil) {
            self.label.backgroundColor = [UIColor greenColor];
        } else {
            self.label.backgroundColor = nil;
        }
    }
    return NO;
}

@end
