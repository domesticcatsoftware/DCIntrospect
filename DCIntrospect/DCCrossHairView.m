//
//  DCCrossHairView.m
//
//  Created by Domestic Cat on 3/05/11.
//

#import "DCCrossHairView.h"

@implementation DCCrossHairView
@synthesize color;

- (void)dealloc
{
	[color release];
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame color:(UIColor *)aColor
{
	if ((self = [super initWithFrame:frame]))
	{
		self.color = aColor;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
	}

	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self.color set];
	CGContextMoveToPoint(context, floorf(self.bounds.size.width / 2) + 0.5, 0);
	CGContextAddLineToPoint(context, floorf(self.bounds.size.width / 2) + 0.5, self.bounds.size.height);
	CGContextStrokePath(context);

	CGContextMoveToPoint(context, 0, floorf(self.bounds.size.height / 2) + 0.5);
	CGContextAddLineToPoint(context, self.bounds.size.width, floorf(self.bounds.size.height / 2) + 0.5);
	CGContextStrokePath(context);
}

@end
