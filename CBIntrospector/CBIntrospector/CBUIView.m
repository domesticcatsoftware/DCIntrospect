//
//  CBUIView.m
//  CBIntrospector
//
//  Created by Christopher Bess on 5/2/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import "CBUIView.h"
#import "JSONKit.h"

@interface CBUIView ()
- (NSDictionary *)dictionaryRepresentation;
@end

@implementation CBUIView
@synthesize syncFilePath;
@synthesize isDirty;
@synthesize className;
@synthesize memoryAddress;
@synthesize hidden = _hidden;
@synthesize alpha = _alpha;
@synthesize bounds = _bounds;
@synthesize center = _center;
@synthesize frame = _frame;
@synthesize viewDescription;

- (id)initWithJSON:(NSDictionary *)jsonInfo
{
    self = [super init];
    if (self)
    {
        if (![self updateWithJSON:jsonInfo])
            return nil;
    }
    return self;
}

- (void)dealloc
{
    self.className = nil;
    self.memoryAddress = nil;
    self.viewDescription = nil;
    self.syncFilePath = nil;
    [super dealloc];
}

#pragma mark - Properties

- (void)setHidden:(BOOL)hidden
{
    _hidden = hidden;
    self.isDirty = YES;
}

- (void)setAlpha:(float)alpha
{
    _alpha = alpha;
    self.isDirty = YES;
}

- (void)setBounds:(CGRect)bounds
{
    _bounds = bounds;
    self.isDirty = YES;
}

- (void)setFrame:(CGRect)frame
{
    if (NSEqualRects(_frame, frame))
        return;
    
    _frame = frame;
    self.isDirty = YES;
}

- (void)setCenter:(CGPoint)center
{
    _center = center;
    self.isDirty = YES;
}

#pragma mark - Misc

- (BOOL)updateWithJSON:(NSDictionary *)jsonInfo
{
    self.className = [jsonInfo valueForKey:kUIViewClassNameKey];
    self.memoryAddress = [jsonInfo valueForKey:kUIViewMemoryAddressKey];
    self.viewDescription = [[jsonInfo valueForKey:kUIViewDescriptionKey] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    self.hidden = [[jsonInfo valueForKey:kUIViewHiddenKey] boolValue];
    self.alpha = [[jsonInfo valueForKey:kUIViewAlphaKey] floatValue];
    
    self.bounds = NSRectFromString([jsonInfo valueForKey:kUIViewBoundsKey]);
    self.center = NSPointFromString([jsonInfo valueForKey:kUIViewCenterKey]);
    self.frame = NSRectFromString([jsonInfo valueForKey:kUIViewFrameKey]);
    
    self.isDirty = NO;
    return YES;
}

- (NSDictionary *)dictionaryRepresentation
{
    // build the JSON/dictionary
    NSMutableDictionary *jsonInfo = [NSMutableDictionary dictionaryWithCapacity:7];
    
    [jsonInfo setObject:self.className forKey:kUIViewClassNameKey];
    [jsonInfo setObject:self.memoryAddress forKey:kUIViewMemoryAddressKey];
    
    [jsonInfo setObject:NSStringFromRect(self.bounds) forKey:kUIViewBoundsKey];
    [jsonInfo setObject:NSStringFromPoint(self.center) forKey:kUIViewCenterKey];
    [jsonInfo setObject:NSStringFromRect(self.frame) forKey:kUIViewFrameKey];
    
    [jsonInfo setObject:[NSNumber numberWithFloat:self.alpha] forKey:kUIViewAlphaKey];
    [jsonInfo setObject:[NSNumber numberWithBool:self.hidden] forKey:kUIViewHiddenKey];
    
    return jsonInfo;
}

- (BOOL)saveJSON
{
    NSDictionary *jsonInfo = [self dictionaryRepresentation];
    
    // save to disk
    NSError *error = nil;
    NSString *jsonString = [jsonInfo JSONString];
    [jsonString writeToFile:self.syncFilePath
                 atomically:YES
                   encoding:NSUTF8StringEncoding
                      error:&error];
    if (error)
    {
        NSAssert(NO, @"Failed to save JSON: %@", error);
        return NO;
    }
    
    self.isDirty = NO;
    return YES;
}
@end
