//
//  DCFrameView.m
//  DCIntrospectDemo
//
//  Created by Domestic Cat on 29/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DCFrameView.h"


@implementation DCFrameView
@synthesize mainRect, superRect;

- (void)dealloc
{
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
	}
	return self;
}

- (void)setMainRect:(CGRect)newMainRect
{
	mainRect = newMainRect;
	[self setNeedsDisplay];
}

- (void)setSuperRect:(CGRect)newSuperRect
{
	superRect = newSuperRect;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, self.bounds);

	[[UIColor blueColor] set];
	mainRect = CGRectMake(mainRect.origin.x + 0.5,
						  mainRect.origin.y + 0.5,
						  mainRect.size.width - 1.0,
						  mainRect.size.height - 1.0);
	CGContextStrokeRect(context, mainRect);

	UIFont *font = [UIFont boldSystemFontOfSize:11];
	CGSize widthTextSize;
	CGSize heightTextSize;
	CGRect mainRectOffset = CGRectOffset(mainRect, -superRect.origin.x, -superRect.origin.y);

	NSString *widthText = [NSString stringWithFormat:@"%.1f", mainRect.size.width];
	widthTextSize = [widthText sizeWithFont:font];
	CGRect widthTextRect = CGRectMake(mainRect.origin.x + (mainRect.size.width - widthTextSize.width) / 2,
									  mainRect.origin.y - widthTextSize.height,
									  widthTextSize.width,
									  widthTextSize.height);
	if (widthTextRect.origin.y < 0)
		widthTextRect.origin.y = 2.0;
	[widthText drawInRect:widthTextRect withFont:font];

	NSString *heightText = [NSString stringWithFormat:@"%.1f", mainRect.size.height];
	heightTextSize = [widthText sizeWithFont:font];
	CGRect heightTextRect = CGRectMake(mainRect.origin.x - heightTextSize.width,
									   mainRect.origin.y + (mainRect.size.height - heightTextSize.height) / 2,
									   widthTextSize.width,
									   widthTextSize.height);
	if (heightTextRect.origin.x < 0)
		heightTextRect.origin.x = 2.0;
	[heightText drawInRect:heightTextRect withFont:font];

	float dash[2] = {3, 3};
	CGContextSetLineDash(context, 0, dash, 2);

	[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.5];

	// edge->left side
	CGContextMoveToPoint(context, superRect.origin.x, floorf(CGRectGetMidY(mainRect)) + 0.5);
	CGContextAddLineToPoint(context, mainRect.origin.x - widthTextSize.width - 2.0, floorf(CGRectGetMidY(mainRect)) + 0.5);
	CGContextStrokePath(context);

	// left side->edge
	CGContextMoveToPoint(context, CGRectGetMaxX(mainRect), floorf(CGRectGetMidY(mainRect)) + 0.5);
	CGContextAddLineToPoint(context, CGRectGetMaxX(superRect), floorf(CGRectGetMidY(mainRect)) + 0.5);
	CGContextStrokePath(context);

	// edge->top side
	CGContextMoveToPoint(context, floorf(CGRectGetMidX(mainRect)) + 0.5, superRect.origin.y);
	CGContextAddLineToPoint(context, floorf(CGRectGetMidX(mainRect)) + 0.5, CGRectGetMinY(mainRect) - heightTextSize.height - 2.0);
	CGContextStrokePath(context);

	// bottom side->edge
	CGContextMoveToPoint(context, floorf(CGRectGetMidX(mainRect)) + 0.5, CGRectGetMaxY(mainRect));
	CGContextAddLineToPoint(context, floorf(CGRectGetMidX(mainRect)) + 0.5, CGRectGetMaxY(superRect));
	CGContextStrokePath(context);
}


@end
