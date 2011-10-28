//
//  DCIntrospectLoader.h
//
//  Created by Stewart Gleadow on 28/10/11.
//
//  Based on an implementation by Pete Hodgson in Frank
//  https://github.com/moredip/Frank/blob/master/src/FrankLoader.m

#ifdef DEBUG

#import "DCIntrospect.h"

@interface DCIntrospectLoader : NSObject
@end

@implementation DCIntrospectLoader

// This is called after application:didFinishLaunchingWithOptions:
// so the statusBarOrientation should be reported correctly
+ (void)applicationDidBecomeActive:(NSNotification *)notification
{
    NSLog(@"Injecting DCIntrospect loader");
    [[DCIntrospect sharedIntrospector] start];
}

+ (void)load
{
    NSLog(@"Injecting DCIntrospect loader");
    
    [[NSNotificationCenter defaultCenter] addObserver:[self class] 
                                             selector:@selector(applicationDidBecomeActive:) 
                                                 name:@"UIApplicationDidBecomeActiveNotification" 
                                               object:nil];
}

@end

#endif
