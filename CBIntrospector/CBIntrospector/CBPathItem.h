//
//  CBPathItem.h
//  CBIntrospector
//
//  Created by Christopher Bess on 6/4/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBPathItem;

/**
 * Represents an operation that will determine if the specified CBPathItem should be stored. You can modify
 * the path item as desired. If the name is nil, then it will not be stored in the items collection.
 * @return YES, to traverse the item, NO to skip it.
 */
typedef BOOL(^CBPathItemStoreItemBlock)(CBPathItem *pathItem);

@interface CBPathItem : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *path; // absolute path to the item
@property (nonatomic, strong) NSArray *subItems; // array of CBPathItems at specified path
/**
 * Returns an array of CBPathItems at the specified path.
 */
+ (NSArray *)pathItemsAtPath:(NSString *)dirPath recursive:(BOOL)recursive block:(CBPathItemStoreItemBlock)block;
@end
