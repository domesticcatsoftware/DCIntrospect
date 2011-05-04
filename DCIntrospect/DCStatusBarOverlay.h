//
//  DCStatusBarOverlay.h
//
//  Copyright 2011 Domestic Cat. All rights reserved.
//

#import "DCIntrospectSettings.h"

#define kDCIntrospectNotificationStatusBarTapped @"kDCIntrospectNotificationStatusBarTapped"

@interface DCStatusBarOverlay : UIWindow
{
}

@property (nonatomic, retain) UILabel *leftLabel;
@property (nonatomic, retain) UILabel *rightLabel;

///////////
// Setup //
///////////

- (id)init;
- (void)updateBarFrame;

/////////////
// Actions //
/////////////

- (void)tapped;

@end
