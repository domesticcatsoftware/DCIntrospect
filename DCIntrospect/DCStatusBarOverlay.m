//
//  DCStatusBarOverlay.m
//
//  Copyright 2011 Domestic Cat. All rights reserved.
//

#import "DCStatusBarOverlay.h"

@implementation DCStatusBarOverlay
@synthesize leftLabel, rightLabel, infoButton;

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];

	[leftLabel release];
	[rightLabel release];

	[super dealloc];
}

#pragma mark Setup

- (id)init
{
    if ((self = [super initWithFrame:CGRectZero]))
	{
        self.windowLevel = UIWindowLevelStatusBar + 1.0f;
        self.frame = [[UIApplication sharedApplication] statusBarFrame];
		self.backgroundColor = [UIColor blackColor];

        UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.frame];
        backgroundImageView.image = [[UIImage imageNamed:@"statusBarBackground.png"] stretchableImageWithLeftCapWidth:2.0f topCapHeight:0.0f];
        [self addSubview:backgroundImageView];
        [backgroundImageView release];

		self.leftLabel = [[[UILabel alloc] initWithFrame:CGRectOffset(self.frame, 2.0, 0.0)] autorelease];
		self.leftLabel.backgroundColor = [UIColor clearColor];
		self.leftLabel.textAlignment = UITextAlignmentLeft;
		self.leftLabel.font = [UIFont boldSystemFontOfSize:12.0];
		self.leftLabel.textColor = [UIColor colorWithWhite:0.97 alpha:1.0];
		self.leftLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview:self.leftLabel];

		self.rightLabel = [[[UILabel alloc] initWithFrame:CGRectOffset(self.frame, -2.0, 0.0)] autorelease];
		self.rightLabel.backgroundColor = [UIColor clearColor];
		self.rightLabel.font = [UIFont boldSystemFontOfSize:12.0];
		self.rightLabel.textAlignment = UITextAlignmentRight;
		self.rightLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		self.rightLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview:self.rightLabel];

		self.infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
		self.infoButton.frame = (CGRect) { self.frame.size.width - 17, 4.0, 12.0, 12.0 };
		self.infoButton.hidden = YES;
		[self addSubview:self.infoButton];
		UITapGestureRecognizer *gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)] autorelease];
		gestureRecognizer.cancelsTouchesInView = NO;
		[self addGestureRecognizer:gestureRecognizer];

		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBarFrame) name:UIDeviceOrientationDidChangeNotification object:nil];
	}

	return self;
}

- (void)updateBarFrame
{
	// current interface orientation
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
	CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;

	CGFloat pi = (CGFloat)M_PI;
	if (orientation == UIDeviceOrientationPortrait) {
		self.transform = CGAffineTransformIdentity;
		self.frame = CGRectMake(0, 0, screenWidth, self.frame.size.height);
	}
	else if (orientation == UIDeviceOrientationLandscapeLeft)
	{
		self.transform = CGAffineTransformMakeRotation(pi * (90) / 180.0f);
		self.frame = CGRectMake(screenWidth - self.frame.size.width, 0, self.frame.size.width, screenHeight);
	}
	else if (orientation == UIDeviceOrientationLandscapeRight)
	{
		self.transform = CGAffineTransformMakeRotation(pi * (-90) / 180.0f);
		self.frame = CGRectMake(0, 0, self.frame.size.width, screenHeight);
	}
	else if (orientation == UIDeviceOrientationPortraitUpsideDown)
	{
		self.transform = CGAffineTransformMakeRotation(pi);
		self.frame = CGRectMake(0, screenHeight - self.frame.size.height, screenWidth, self.frame.size.height);
	}
}

#pragma mark Actions

- (void)tapped
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kDCIntrospectNotificationStatusBarTapped object:nil];
}

@end
