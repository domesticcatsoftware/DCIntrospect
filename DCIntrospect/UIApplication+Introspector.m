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

@interface NSObject (Private)
- (void)_gsEvent; // from private API, hush-up warnings
@end

@interface UIApplication (Custom)
- (void)cb_sendEvent:(UIEvent *)evt;
@end

static IMP gOrigSendEvent = nil;

#define GSEVENT_TYPE 2
//#define GSEVENT_SUBTYPE 3
//#define GSEVENT_LOCATION 4
//#define GSEVENT_WINLOCATION 6
//#define GSEVENT_WINCONTEXTID 8
//#define GSEVENT_TIMESTAMP 9
//#define GSEVENT_WINREF 11
#define GSEVENT_FLAGS 12
//#define GSEVENT_SENDERPID 13
//#define GSEVENT_INFOSIZE 14

#define GSEVENTKEY_KEYCODE_CHARIGNORINGMOD 15
//#define GSEVENTKEY_CHARSET_CHARSET 16
//#define GSEVENTKEY_ISKEYREPEATING 17 // ??

#define GSEVENT_TYPE_KEYDOWN 10
#define GSEVENT_TYPE_KEYUP 11

#define GSEVENT_TYPE 2
#define GSEVENT_FLAGS 12
#define GSEVENTKEY_KEYCODE 15
#define GSEVENT_TYPE_KEYUP 11

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
    static int gShakeCount = 0; // needs 2 to start/stop (begin/end events)
    
    gOrigSendEvent(self, @selector(sendEvent:), event);
    
//    DLog(@"event: %@", event);
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
                return;
            }
        }
    } 
    
    // handle any other events
    if ([event respondsToSelector:@selector(_gsEvent)]) 
    {
        // Key events come in form of UIInternalEvents.
        // They contain a GSEvent object which contains 
        // a GSEventRecord among other things
        
        int *eventMem = (int *)[event performSelector:@selector(_gsEvent)];
        if (eventMem) 
        {
            int eventType = eventMem[GSEVENT_TYPE];
            if (eventType == GSEVENT_TYPE_KEYDOWN) 
            {   
                // Read keycode from GSEventKey
                int tmp = eventMem[GSEVENTKEY_KEYCODE];
                UniChar *keycode = (UniChar *)&tmp;
                
                /* 
                 Some Keycodes found
                 ===================
                 
                 Alphabet
                 a = 4
                 b = 5
                 c = ...
                 z = 29
                 
                 Numbers
                 1 = 30
                 2 = 31
                 3 = ...
                 9 = 38
                 
                 Space bar = 44
                 
                 Arrows
                 Right = 79
                 Left = 80
                 Down = 81
                 Up = 82
                 
                 Flags found
                 ===========
                 
                 Cmd = 1 << 17
                 Shift = 1 << 18
                 Ctrl = 1 << 19
                 Alt = 1 << 20
                 */
                // DebugLog(@"keycode: %@", keyCode);

                NSNumber *keyCode = [NSNumber numberWithShort:keycode[0]];
                // [space] key
                if ([keyCode isEqualToNumber:[NSNumber numberWithInt:44]])
                {
                    [introspector invokeIntrospector];
                }
            }
        }
    }
    #endif
}
@end
