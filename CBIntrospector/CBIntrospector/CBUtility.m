//
//  CBUtility.m
//  CBIntrospector
//
//  Created by Christopher Bess on 5/3/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import "CBUtility.h"

@implementation CBUtility
+ (CBUtility *)sharedInstance
{
    static CBUtility *sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [CBUtility new];
    });
    
    return sharedObject;
}

- (void)showMessageBoxWithString:(NSString *)msg
{
	NSAlert *alert = [NSAlert new];
	[alert setMessageText:msg];
	
	[alert runModal];
	[alert release];
}
@end
