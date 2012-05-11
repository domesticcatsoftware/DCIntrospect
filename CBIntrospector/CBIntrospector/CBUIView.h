//
//  CBUIView.h
//  CBIntrospector
//
//  Created by Christopher Bess on 5/2/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CBUIView : NSObject
@property (nonatomic, copy) NSString *syncFilePath;
@property (nonatomic, assign) BOOL isDirty;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSString *memoryAddress;
@property (nonatomic, copy) NSString *viewDescription;
@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, assign) float alpha;
@property (nonatomic, assign) NSRect bounds;
@property (nonatomic, assign) NSPoint center;
@property (nonatomic, assign) NSRect frame;

- (id)initWithJSON:(NSDictionary *)jsonInfo;
- (BOOL)updateWithJSON:(NSDictionary *)jsonInfo;
- (BOOL)saveJSON;
@end
