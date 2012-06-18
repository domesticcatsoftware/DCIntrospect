//
//  CBPathItem.m
//  CBIntrospector
//
//  Created by Christopher Bess on 6/4/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import "CBPathItem.h"

@implementation CBPathItem
@synthesize name;
@synthesize path;
@synthesize subItems;

+ (NSArray *)pathItemsAtPath:(NSString *)dirPath recursive:(BOOL)recursive block:(CBPathItemStoreItemBlock)block
{
    NSMutableArray *pathItems = [NSMutableArray arrayWithCapacity:10];
    NSFileManager *mgr = [NSFileManager defaultManager];
    if (![mgr fileExistsAtPath:dirPath])
        return pathItems;
    
    NSError *error = nil;
    NSArray *paths = [mgr contentsOfDirectoryAtPath:dirPath error:&error];
    if (error)
    {
        
        DebugLog(@"error iterating path: %@", error);
        return pathItems;
    }
        
    // iterate path
    @autoreleasepool {
        for (NSString *path in paths)
        {
            CBPathItem *item = NSAutoRelease([CBPathItem new]);
            NSString *fullPath = [dirPath stringByAppendingPathComponent:path];
            item.path = fullPath;
            item.name = path;
            
            if (block)
            {
                if (!block(item))
                    continue;
            }
            
            if (recursive)
            {
                NSArray *items = [CBPathItem pathItemsAtPath:fullPath recursive:YES block:block];
                if (item.name)
                {
                    item.subItems = items;
                    [pathItems addObject:item];
                }
            }
            else if (item.name)
            {
                [pathItems addObject:item];
            }
        }
    }
    
    return pathItems;
}

- (NSString *)description
{
    return nssprintf(@"<CBPathItem: %@ - %@>", self.name, self.path);
}
@end
