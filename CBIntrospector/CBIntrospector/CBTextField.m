//
//  CBTextField.m
//  CBIntrospector
//
//  Created by Christopher Bess on 5/6/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import "CBTextField.h"

@implementation CBTextField
- (BOOL)becomeFirstResponder
{
    BOOL isResponder = [super becomeFirstResponder];
    if ([[self delegate] respondsToSelector:@selector(controlDidBecomeFirstResponder:)])
    {
        if (isResponder)
            [(id<CBTextFieldDelegate>)[self delegate] controlDidBecomeFirstResponder:self];
    }
    return isResponder;
}
@end
