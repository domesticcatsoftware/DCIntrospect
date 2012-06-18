//
//  DCUtility.m
//  DCIntrospectDemo
//
//  Created by Christopher Bess on 4/30/12.
//  Copyright (c) 2012 Christopher Bess. All rights reserved.
//

#import "DCUtility.h"
#import "CBSharedHeader.h"
#import "CBIntrospectConstants.h"

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

- (NSString *)describeColor:(UIColor *)color
{
	if (!color)
		return @"nil";
	
	NSString *returnString = nil;
	if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelRGB)
	{
		const CGFloat *components = CGColorGetComponents(color.CGColor);
		returnString = [NSString stringWithFormat:@"R: %.0f G: %.0f B: %.0f A: %.2f",
						components[0] * 256,
						components[1] * 256,
						components[2] * 256,
						components[3]];
	}
	else
	{
		returnString = [NSString stringWithFormat:@"%@ (incompatible color space)", color];
	}
	return returnString;
}

@end
