//
//  CustomDrawnView.m
//  DCIntrospectDemo
//
//  Created by Domestic Cat on 4/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CustomDrawnView.h"
#import "DCIntrospect.h"

@implementation CustomDrawnView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	[[DCIntrospect sharedIntrospector] flashRect:rect inView:self];

	[@"This is a custom drawn view." drawInRect:CGRectMake(0, 0, self.bounds.size.width, 12) withFont:[UIFont boldSystemFontOfSize:12]];
	[[NSString stringWithFormat:@"%i", number] drawInRect:CGRectMake(0, 12, self.bounds.size.width, 12) withFont:[UIFont boldSystemFontOfSize:12]];
}

- (void)dealloc
{
    [super dealloc];
}

@end
