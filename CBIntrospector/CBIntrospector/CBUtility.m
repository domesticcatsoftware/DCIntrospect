//
//  CBUtility.m
//  CBIntrospector
//
//  Created by Christopher Bess on 5/3/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import "CBUtility.h"
#import "JSONKit.h"

@implementation CBUtility
+ (CBUtility *)sharedInstance
{
    static CBUtility *sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [CBUtility new];
    });
    
    return sharedObject;
}

- (void)showMessageBoxWithString:(NSString *)msg
{
	NSAlert *alert = [NSAlert new];
	[alert setMessageText:msg];
	
	[alert runModal];
	[alert release];
}

- (NSDictionary *)dictionaryWithJSONFilePath:(NSString *)path
{
    NSError *error = nil;
    NSString *jsonString = [[[NSString alloc] initWithContentsOfFile:path
                                                            encoding:NSUTF8StringEncoding
                                                               error:&error] autorelease];
    if (error)
        return nil;
    
    NSDictionary *jsonInfo = [jsonString objectFromJSONString];
    return jsonInfo;
}

- (int)updateIntValueWithTextField:(NSTextField *)textField addValue:(NSInteger)addValue
{
    if (!textField)
        return 0;
    
    textField.intValue = textField.intValue + addValue;
    return textField.intValue;
}
@end
