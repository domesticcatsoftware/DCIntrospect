//
//  DCUIViewSwizzle.m
//
//  Created by Domestic Cat on 3/05/11.
//

#import "DCUIViewSwizzle.h"
#import <objc/runtime.h> 
#import <objc/message.h>

// swizzle from mike ash
void Swizzle(Class c, SEL orig, SEL new)
{
	Method origMethod = class_getInstanceMethod(c, orig);
	Method newMethod = class_getInstanceMethod(c, new);
	if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
		class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
	else
		method_exchangeImplementations(origMethod, newMethod);
}

@implementation UIView (swizzled)
@dynamic flashOnRedraw;

- (void *)flashOnRedraw_key
{
	static char assocKey;
	return &assocKey;
}

- (void)setFlashOnRedraw:(BOOL)v
{
	NSNumber *flashOnRedraw_bool = [NSNumber numberWithBool:v];
	objc_setAssociatedObject(self, self.flashOnRedraw_key, flashOnRedraw_bool, OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)flashOnRedraw
{
	NSNumber *associatedObject = (NSNumber *)objc_getAssociatedObject(self, self.flashOnRedraw_key);
	return [associatedObject boolValue];
}

- (void)flashDrawRect:(CGRect)rect
{
	if (self.flashOnRedraw)
	{
		UIView *view = [[[UIView alloc] initWithFrame:rect] autorelease];
		view.backgroundColor = [UIColor redColor];
		[self addSubview:view];
		[view performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.05];
	}

	[self flashDrawRect:rect];
}

@end
