//
//  DCStatusBarOverlay.h
//
//  Copyright 2011 Domestic Cat. All rights reserved.
//

// Based mainly on @myellow's excellent MTStatusBarOverlay: https://github.com/myell0w/MTStatusBarOverlay


#import "DCIntrospectSettings.h"

#define kDCIntrospectNotificationStatusBarTapped @"kDCIntrospectNotificationStatusBarTapped"

@interface DCStatusBarOverlay : UIWindow
{
}

@property (nonatomic, strong) UILabel *leftLabel;
@property (nonatomic, strong) UILabel *rightLabel;

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
