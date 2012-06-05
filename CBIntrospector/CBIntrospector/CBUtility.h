//
//  CBUtility.h
//  CBIntrospector
//
//  Created by Christopher Bess on 5/3/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CBUtility : NSObject
+ (CBUtility *)sharedInstance;

- (void)showMessageBoxWithString:(NSString *)msg;
- (NSDictionary *)dictionaryWithJSONFilePath:(NSString *)path;
- (int)updateIntValueWithTextField:(NSTextField *)textField addValue:(NSInteger)addValue;
- (NSString *)simulatorDirectoryPath;
@end
