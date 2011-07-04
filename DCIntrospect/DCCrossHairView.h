//
//  DCCrossHairView.h
//
//  Created by Domestic Cat on 3/05/11.
//

#ifdef DEBUG

@interface DCCrossHairView : UIView
{
}

@property (nonatomic, retain) UIColor *color;

- (id)initWithFrame:(CGRect)frame color:(UIColor *)aColor;

@end

#endif
