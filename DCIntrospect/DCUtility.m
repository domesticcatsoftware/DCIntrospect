//
//  DCUtility.m
//  DCIntrospectDemo
//
//  Created by Christopher Bess on 4/30/12.
//  Copyright (c) 2012 Christopher Bess. All rights reserved.
//

#import "DCUtility.h"
#import "CBSharedHeader.h"

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

- (BOOL)writeString:(NSString *)string toPath:(NSString *)path
{
    NSError *error = nil;
    
    // store the json file
    [string writeToFile:path
             atomically:NO
               encoding:NSUTF8StringEncoding
                  error:&error];
    
    NSAssert(error == nil, @"error storing string: %@", error);
    
    return error == nil;
}

- (NSString *)currentViewJSONFilePath
{
    return [[[DCUtility sharedInstance] cacheDirectoryPath] stringByAppendingPathComponent:kCBCurrentViewFileName];
}

- (NSString *)viewTreeJSONFilePath
{
    return [[[DCUtility sharedInstance] cacheDirectoryPath] stringByAppendingPathComponent:kCBTreeDumpFileName];
}
@end
