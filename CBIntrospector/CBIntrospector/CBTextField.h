//
//  CBTextField.h
//  CBIntrospector
//
//  Created by Christopher Bess on 5/6/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CBTextField : NSTextField

@end

@protocol CBTextFieldDelegate <NSObject>
- (void)controlDidBecomeFirstResponder:(NSResponder *)responder;
@end