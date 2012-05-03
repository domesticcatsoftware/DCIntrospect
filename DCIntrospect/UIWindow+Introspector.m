//
//  UIWindow+Introspector.m
//  DCIntrospectDemo
//
//  Created by C Bess on 4/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIWindow+Introspector.h"
#import "DCIntrospect.h"

@interface UIWindow (Custom)
- (void)_sendEvent:(UIEvent *)evt;
@end

static IMP gOrigSendEvent = nil;

@implementation UIWindow (Introspector)
+ (void)replaceCanonicalSendEvent
{
    SEL origSendEventSelector = @selector(sendEvent:);
    SEL mySendEventSelector = @selector(_sendEvent:);

    Method mySendEventMethod = class_getInstanceMethod([UIWindow class], mySendEventSelector);
    gOrigSendEvent = class_replaceMethod([UIWindow class], origSendEventSelector, method_getImplementation(mySendEventMethod), method_getTypeEncoding(mySendEventMethod));
}

- (void)_sendEvent:(UIEvent *)event
{
#ifdef DEBUG
    static int gShakeCount = 0; // needs 2 to start/stop (motion begin/end events)
    
    gOrigSendEvent(self, @selector(sendEvent:), event);
    
    DCIntrospect *introspector = [DCIntrospect sharedIntrospector];
    
    // allow shake to activate
    if (introspector.enableShakeToActivate)
    {
        if ([NSStringFromClass([event class]) isEqualToString:@"UIMotionEvent"])
        {
            // toggle introspector
            if (++gShakeCount == 2)
            {
                [introspector invokeIntrospector];
                gShakeCount = 0; 
            }
        }
    }
#endif
}
@end
