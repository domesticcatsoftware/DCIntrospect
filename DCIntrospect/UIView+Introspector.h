//
//  UIView+Introspector.h
//  DCIntrospectDemo
//
//  Created by Christopher Bess on 4/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Introspector)
@property (nonatomic, readonly) NSString *memoryAddress;

+ (NSString *)describeProperty:(NSString *)propertyName value:(id)value;

#pragma mark - Persistence
/**
 * Stores the specified view in the file store.
 */
+ (void)storeView:(UIView *)view;

/**
 * Loads and updates the specified view from the file store.
 */
+ (void)restoreView:(UIView *)view;

/**
 * Clears the file data for the specified view.
 */
+ (void)unlinkView:(UIView *)view;

#pragma mark - Transform
- (NSDictionary *)dictionaryRepresentation;
- (NSString *)JSONString;
/**
 * Updates the current view using the values restored from the specified JSON object.
 * @return YES if the JSON was successfully loaded, NO if the class or memory address for this view
 * did not match what was stored.
 */
- (BOOL)updateWithJSON:(NSDictionary *)jsonInfo;

/**
 * Returns the file path used to sync this view.
 */
- (NSString *)syncFilePath;

- (NSString *)viewDescription;
@end
