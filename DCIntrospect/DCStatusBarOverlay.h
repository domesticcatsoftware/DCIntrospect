//
//  DCStatusBarOverlay.h
//
//  Copyright 2011 Domestic Cat. All rights reserved.
//

#import "DCIntrospectDefines.h"

@interface DCStatusBarOverlay : UIWindow
{
    
}

@property (nonatomic, retain) UILabel *leftLabel;
@property (nonatomic, retain) UILabel *rightLabel;
@property (nonatomic, retain) UIButton *infoButton;

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
