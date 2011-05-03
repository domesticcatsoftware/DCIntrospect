//
//  DCUIViewSwizzle.h
//
//  Created by Domestic Cat on 3/05/11.
//
// 
// http://pastie.org/pastes/992775/reply

void Swizzle(Class c, SEL orig, SEL new);

@interface UIView (swizzled)

@property (nonatomic, assign) BOOL flashOnRedraw;
@property (readonly) void* flashOnRedraw_key;

- (void)flashDrawRect:(CGRect)rect;

@end
