//
//  DCFrameView.h
//
//  Created by Domestic Cat on 29/04/11.
//

#import <QuartzCore/QuartzCore.h>
#import "DCCrossHairView.h"

@protocol DCFrameViewDelegate <NSObject>

@required

- (void)touchAtPoint:(CGPoint)point;

@end

@interface DCFrameView : UIView
{

}

@property (nonatomic, assign) id<DCFrameViewDelegate> delegate;
@property (nonatomic) CGRect mainRect;
@property (nonatomic) CGRect superRect;
@property (nonatomic, strong) UILabel *touchPointLabel;
@property (nonatomic, strong) NSMutableArray *rectsToOutline;
@property (nonatomic, strong) DCCrossHairView *touchPointView;

///////////
// Setup //
///////////

- (id)initWithFrame:(CGRect)frame delegate:(id)aDelegate;

////////////////////
// Custom Setters //
////////////////////

- (void)setMainRect:(CGRect)newMainRect;
- (void)setSuperRect:(CGRect)newSuperRect;

/////////////////////
// Drawing/Display //
/////////////////////

- (void)drawRect:(CGRect)rect;

////////////////////
// Touch Handling //
////////////////////

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

@end
