//
//  CBSharedConstants.h
//  DCIntrospectDemo
//
//  Created by Christopher Bess on 5/2/12.
//  Copyright (c) 2012 Christopher Bess. All rights reserved.
//

#ifndef CBIntrospector_CBSharedConstants_h
#define CBIntrospector_CBSharedConstants_h

// alias for [NSString stringWithFormat:format, ...]
static NSString * nssprintf(NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *string = [[NSString alloc] initWithFormat:format 
                                              arguments:args];
    va_end(args);
    
	return NSAutoRelease(string);
}

#endif
