//
//  UIView+Introspector.m
//  DCIntrospectDemo
//
//  Created by Christopher Bess on 4/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIView+Introspector.h"
#import "DCUtility.h"
#import "JSONKit.h"
#import "CBSharedConstants.h"

@interface UIView (Custom)
+ (NSString *)filePathWithView:(UIView *)view;
@end

@implementation UIView (Introspector)

#pragma mark - Persistence
+ (NSString *)filePathWithView:(UIView *)view;
{
//    NSString *filename = [NSString stringWithFormat:@"%@.%x.view.json", NSStringFromClass([view class]), view]; // gen unique filenames
    NSString *filename = kUIViewFileName;
    return [[[DCUtility sharedInstance] cacheDirectoryPath] stringByAppendingPathComponent:filename];
}

+ (void)storeView:(UIView *)view
{
    NSString *jsonString = [view JSONString];
    NSError *error = nil;
    
    // store the json file
    [jsonString writeToFile:[self filePathWithView:view]
                 atomically:NO
                   encoding:NSUTF8StringEncoding
                      error:&error];
    
    NSAssert(error == nil, @"error saving view: %@", error);
}

+ (void)restoreView:(UIView *)view
{
    NSError *error = nil;
    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:[self filePathWithView:view]
                                                           encoding:NSUTF8StringEncoding
                                                              error:&error];
    NSDictionary *jsonInfo = [jsonString objectFromJSONString];
    if ([view updateWithJSON:jsonInfo])
    {
        // success
    }
    else
    {
        // fail
    }
    
    NSAssert(error == nil, @"error reading view: %@", error);
    [jsonString release];
}

+ (void)unlinkView:(UIView *)view
{
    [[NSFileManager defaultManager] removeItemAtPath:[self filePathWithView:view] error:nil];
}

#pragma mark - Transform
- (NSDictionary *)dictionaryRepresentation
{
    // build the JSON/dictionary
    NSMutableDictionary *jsonInfo = [NSMutableDictionary dictionaryWithCapacity:7];
    
    [jsonInfo setObject:NSStringFromClass([self class]) forKey:kUIViewClassNameKey];
    [jsonInfo setObject:[NSString stringWithFormat:@"%x", self] forKey:kUIViewMemoryAddressKey];
    
    [jsonInfo setObject:NSStringFromCGRect(self.bounds) forKey:kUIViewBoundsKey];
    [jsonInfo setObject:NSStringFromCGPoint(self.center) forKey:kUIViewCenterKey];
    [jsonInfo setObject:NSStringFromCGRect(self.frame) forKey:kUIViewFrameKey];
    
    [jsonInfo setObject:[NSNumber numberWithFloat:self.alpha] forKey:kUIViewAlphaKey];
    [jsonInfo setObject:[NSNumber numberWithBool:self.hidden] forKey:kUIViewHiddenKey];
    
    return jsonInfo;
}

- (NSString *)JSONString
{
    return [[self dictionaryRepresentation] JSONString];
}

- (BOOL)updateWithJSON:(NSDictionary *)jsonInfo
{
    // check class and mem address    
    NSString *memAddress = [jsonInfo valueForKey:kUIViewMemoryAddressKey];
    if (![[NSString stringWithFormat:@"%x", self] isEqualToString:memAddress])
        return NO;
    else if (![[jsonInfo valueForKey:kUIViewClassNameKey] isEqualToString:NSStringFromClass([self class])])
        return NO;
    
    self.hidden = [[jsonInfo valueForKey:kUIViewHiddenKey] boolValue];
    self.alpha = [[jsonInfo valueForKey:kUIViewAlphaKey] floatValue];
    
    // only update what was changed, frame overrides all (because it is a calculation of bounds & center)
    CGRect newBounds = CGRectFromString([jsonInfo valueForKey:kUIViewBoundsKey]);
    BOOL changedBounds = (!CGRectEqualToRect(newBounds, self.bounds));
    
    CGPoint newCenter = CGPointFromString([jsonInfo valueForKey:kUIViewCenterKey]);
    BOOL changedCenter = (!CGPointEqualToPoint(newCenter, self.center));
    
    CGRect newFrame = CGRectFromString([jsonInfo valueForKey:kUIViewFrameKey]);
    BOOL changedFrame = (!CGRectEqualToRect(newFrame, self.frame));
        
    if (changedBounds)
        self.bounds = newBounds;
    
    if (changedCenter)
        self.center = newCenter;
    
    if (changedFrame)
        self.frame = newFrame;
    
    return YES;
}

- (NSString *)syncFilePath
{
    return [UIView filePathWithView:self];
}
@end
