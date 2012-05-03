//
//  DCUtility.m
//  DCIntrospectDemo
//
//  Created by Christopher Bess on 4/30/12.
//  Copyright (c) 2012 Christopher Bess. All rights reserved.
//

#import "DCUtility.h"

@implementation DCUtility
+ (DCUtility *)sharedInstance
{
    static DCUtility *sharedObj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObj = [DCUtility new];
    });
    
    return sharedObj;
}

- (NSString *)cacheDirectoryPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
	
	return libraryDirectory;
}
@end
