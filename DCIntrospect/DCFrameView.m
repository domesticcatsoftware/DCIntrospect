//
//  DCFrameView.m
//
//  Created by Domestic Cat on 29/04/11.
//

#import "DCFrameView.h"

@implementation DCFrameView
@synthesize delegate;
@synthesize mainRect, superRect;
@synthesize touchPointLabel;
@synthesize rectsToOutline;
@synthesize touchPointView;

- (void)dealloc
{
	self.delegate = nil;
	[touchPointLabel release];
	[touchPointView release];

	[super dealloc];
}

#pragma Setup

- (id)initWithFrame:(CGRect)frame delegate:(id)aDelegate
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.delegate = aDelegate;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;

		self.touchPointLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		self.touchPointLabel.text = @"X 320 Y 480";
		self.touchPointLabel.font = [UIFont boldSystemFontOfSize:12.0];
		self.touchPointLabel.textAlignment = UITextAlignmentCenter;
		self.touchPointLabel.textColor = [UIColor whiteColor];
		self.touchPointLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.65];
		self.touchPointLabel.layer.cornerRadius = 5.5;
		self.touchPointLabel.layer.masksToBounds = YES;
		self.touchPointLabel.alpha = 0.0;
		[self addSubview:self.touchPointLabel];

		self.rectsToOutline = [NSMutableArray array];

		self.touchPointView = [[[DCCrossHairView alloc] initWithFrame:CGRectMake(0, 0, 17.0, 17.0) color:[UIColor blueColor]] autorelease];
		self.touchPointView.alpha = 0.0;
		[self addSubview:self.touchPointView];
	}
	return self;
}

#pragma Custom Setters

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

#pragma Drawing/Display

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();

	if (self.rectsToOutline.count > 0)
	{
		for (NSValue *value in self.rectsToOutline)
		{
			UIColor *randomColor = [UIColor colorWithRed:(arc4random() % 256) / 256.0
												   green:(arc4random() % 256) / 256.0
													blue:(arc4random() % 256) / 256.0
												   alpha:1.0];
			[randomColor set];
			CGRect valueRect = [value CGRectValue];
			valueRect = CGRectMake(valueRect.origin.x + 0.5,
                                   valueRect.origin.y + 0.5,
                                   valueRect.size.width - 1.0,
                                   valueRect.size.height - 1.0);
			CGContextStrokeRect(context, valueRect);
		}
		return;
	}

	if (CGRectIsEmpty(self.mainRect))
		return;

	CGRect mainRectOffset = CGRectOffset(mainRect, -superRect.origin.x, -superRect.origin.y);
	BOOL showAntialiasingWarning = NO;
	if (! CGRectIsEmpty(self.superRect))
	{
		if ((mainRectOffset.origin.x != floorf(mainRectOffset.origin.x) && mainRect.origin.x != 0) || (mainRectOffset.origin.y != floor(mainRectOffset.origin.y) && mainRect.origin.y != 0))
		showAntialiasingWarning = YES;
	}

	if (showAntialiasingWarning)
	{
		[[UIColor redColor] set];
		NSLog(@"DCIntrospect: *** WARNING: One or more values of this view's frame are non-integer values. This view will likely look blurry. ***");
	}
	else
	{
		[[UIColor blueColor] set];
	}

	CGRect adjustedMainRect = CGRectMake(self.mainRect.origin.x + 0.5,
										 self.mainRect.origin.y + 0.5,
										 self.mainRect.size.width - 1.0,
										 self.mainRect.size.height - 1.0);
	CGContextStrokeRect(context, adjustedMainRect);

	UIFont *font = [UIFont systemFontOfSize:10.0];

	float dash[2] = {3, 3};
	CGContextSetLineDash(context, 0, dash, 2);

	// edge->left side
	CGContextMoveToPoint(context, CGRectGetMinX(self.superRect), floorf(CGRectGetMidY(adjustedMainRect)) + 0.5);
	CGContextAddLineToPoint(context, CGRectGetMinX(adjustedMainRect), floorf(CGRectGetMidY(adjustedMainRect)) + 0.5);
	CGContextStrokePath(context);

	NSString *leftDistanceString = (showAntialiasingWarning) ? [NSString stringWithFormat:@"%.1f", CGRectGetMinX(mainRectOffset)] : [NSString stringWithFormat:@"%.0f", CGRectGetMinX(mainRectOffset)];
	CGSize leftDistanceStringSize = [leftDistanceString sizeWithFont:font];
	[leftDistanceString drawInRect:CGRectMake(CGRectGetMinX(superRect) + 1.0,
											  floorf(CGRectGetMidY(adjustedMainRect)) - leftDistanceStringSize.height,
											  leftDistanceStringSize.width,
											  leftDistanceStringSize.height)
						  withFont:font];

	// right side->edge
	if (CGRectGetMaxX(self.mainRect) < CGRectGetMaxX(self.superRect))
	{
		CGContextMoveToPoint(context, CGRectGetMaxX(adjustedMainRect), floorf(CGRectGetMidY(adjustedMainRect)) + 0.5);
		CGContextAddLineToPoint(context, CGRectGetMaxX(self.superRect), floorf(CGRectGetMidY(adjustedMainRect)) + 0.5);
		CGContextStrokePath(context);
	}
	NSString *rightDistanceString = (showAntialiasingWarning) ? [NSString stringWithFormat:@"%.1f", CGRectGetMaxX(self.superRect) - CGRectGetMaxX(adjustedMainRect) - 0.5] : [NSString stringWithFormat:@"%.0f", CGRectGetMaxX(self.superRect) - CGRectGetMaxX(adjustedMainRect) - 0.5];
	CGSize rightDistanceStringSize = [rightDistanceString sizeWithFont:font];
	[rightDistanceString drawInRect:CGRectMake(CGRectGetMaxX(self.superRect) - rightDistanceStringSize.width - 1.0,
											   floorf(CGRectGetMidY(adjustedMainRect)) - 0.5 - rightDistanceStringSize.height,
											   rightDistanceStringSize.width,
											   rightDistanceStringSize.height)
						   withFont:font];

	// edge->top side
	CGContextMoveToPoint(context, floorf(CGRectGetMidX(adjustedMainRect)) + 0.5, self.superRect.origin.y);
	CGContextAddLineToPoint(context, floorf(CGRectGetMidX(adjustedMainRect)) + 0.5, CGRectGetMinY(adjustedMainRect));
	CGContextStrokePath(context);
	NSString *topDistanceString = (showAntialiasingWarning) ? [NSString stringWithFormat:@"%.1f",  mainRectOffset.origin.y] : [NSString stringWithFormat:@"%.0f", mainRectOffset.origin.y];
	CGSize topDistanceStringSize = [topDistanceString sizeWithFont:font];
	[topDistanceString drawInRect:CGRectMake(floorf(CGRectGetMidX(adjustedMainRect)) + 3.0,
											   floorf(CGRectGetMinY(self.superRect)),
											   topDistanceStringSize.width,
											   topDistanceStringSize.height)
						   withFont:font];

	// bottom side->edge
	if (CGRectGetMaxY(self.mainRect) < CGRectGetMaxY(self.superRect))
	{
		CGContextMoveToPoint(context, floorf(CGRectGetMidX(adjustedMainRect)) + 0.5, CGRectGetMaxY(adjustedMainRect));
		CGContextAddLineToPoint(context, floorf(CGRectGetMidX(adjustedMainRect)) + 0.5, CGRectGetMaxY(self.superRect));
		CGContextStrokePath(context);
	}
	NSString *bottomDistanceString = (showAntialiasingWarning) ? [NSString stringWithFormat:@"%.1f",  CGRectGetMaxY(self.superRect) - CGRectGetMaxY(mainRectOffset)] : [NSString stringWithFormat:@"%.0f", self.superRect.size.height - mainRectOffset.origin.y - mainRectOffset.size.height];
	CGSize bottomDistanceStringSize = [bottomDistanceString sizeWithFont:font];
	[bottomDistanceString drawInRect:CGRectMake(floorf(CGRectGetMidX(adjustedMainRect)) + 3.0,
												floorf(CGRectGetMaxY(self.superRect)) - bottomDistanceStringSize.height - 1.0,
												bottomDistanceStringSize.width,
												bottomDistanceStringSize.height)
							withFont:font];

}

#pragma Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGFloat labelDistance = 16.0;
	CGPoint touchPoint = [[touches anyObject] locationInView:self];

	// adjust the point so it's exactly on the point of the mouse cursor
	touchPoint.x -= 1;
	touchPoint.y -= 2;

	NSString *touchPontLabelString = [NSString stringWithFormat:@"%.0f, %.0f", touchPoint.x, touchPoint.y];
	self.touchPointLabel.text = touchPontLabelString;

	CGSize stringSize = [touchPontLabelString sizeWithFont:touchPointLabel.font];
	CGRect frame = CGRectMake(touchPoint.x - floorf(stringSize.width / 2) - 5.0,
							  touchPoint.y - stringSize.height - labelDistance,
							  stringSize.width + 11.0,
							  stringSize.height + 4.0);

	// make sure the label stays inside the frame
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	CGFloat minY = UIInterfaceOrientationIsPortrait(orientation) ? [UIApplication sharedApplication].statusBarFrame.size.height : [UIApplication sharedApplication].statusBarFrame.size.width;
	minY += 2.0;		// to keep it touching the top bar
	if (frame.origin.x < 2.0)
		frame.origin.x = 2.0;
	else if (CGRectGetMaxX(frame) > self.bounds.size.width - 2.0)
		frame.origin.x = self.bounds.size.width - frame.size.width - 2.0;
	if (frame.origin.y < minY)
		frame.origin.y = touchPoint.y + stringSize.height + 4.0;

	self.touchPointLabel.frame = frame;
	self.touchPointView.center = CGPointMake(touchPoint.x + 0.5, touchPoint.y + 0.5);
	self.touchPointView.alpha = self.touchPointLabel.alpha = 1.0;

	[self.delegate touchAtPoint:touchPoint];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[UIView animateWithDuration:0.08 animations:^{
		self.touchPointView.alpha = self.touchPointLabel.alpha = 0.0;
	}];
}

@end
