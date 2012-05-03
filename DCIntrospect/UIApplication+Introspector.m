//
//  UIApplication+Introspector.m
//  DCIntrospectDemo
//
//  Created by Christopher Bess on 5/3/12.
//  Copyright (c) 2012 Christopher Bess. All rights reserved.
//

#import "UIApplication+Introspector.h"
#import <objc/objc-class.h>
#import "DCIntrospect.h"

@interface UIApplication (Custom)
- (void)cb_sendEvent:(UIEvent *)evt;
@end

static int gShakeCount = 0; // needs 2 to start/stop (begin/end events)
static IMP gOrigSendEvent = nil;

@implementation UIApplication (Introspector)
+ (void)replaceCanonicalSendEvent
{
#ifdef DEBUG
    SEL origSendEventSelector = @selector(sendEvent:);
    SEL mySendEventSelector = @selector(cb_sendEvent:);
    
    Method mySendEventMethod = class_getInstanceMethod([UIApplication class], mySendEventSelector);
    gOrigSendEvent = class_replaceMethod([UIApplication class], origSendEventSelector, method_getImplementation(mySendEventMethod), method_getTypeEncoding(mySendEventMethod));
#endif
}

- (void)cb_sendEvent:(UIEvent *)event
{
#ifdef DEBUG
    gOrigSendEvent(self, @selector(sendEvent:), event);
    
    DLog(@"event: %@", event);
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
