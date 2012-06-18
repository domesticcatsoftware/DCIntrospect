//
//  CBMacros.h
//  CBIntrospector
//
//  Created by Christopher Bess on 5/12/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#ifndef CBIntrospector_CBMacros_h
#define CBIntrospector_CBMacros_h

#pragma mark - ARC Support
#define HAS_ARC __has_feature(objc_arc)

#if HAS_ARC
#define STRONGRETAIN strong
#define WEAKASSIGN weak
#define NO_ARC(BLOCK_NO_ARC) ;
#define IF_ARC(BLOCK_ARC, BLOCK_NO_ARC) BLOCK_ARC
#else
#define STRONGRETAIN retain
#define WEAKASSIGN assign
#define NO_ARC(BLOCK_NO_ARC) BLOCK_NO_ARC
#define IF_ARC(BLOCK_ARC, BLOCK_NO_ARC) BLOCK_NO_ARC
#endif

#define NSRelease(OBJ) NO_ARC([OBJ release]); OBJ = nil;
#define NSAutoRelease(OBJ) IF_ARC(OBJ, [OBJ autorelease]);
#define NSRetain(OBJ) IF_ARC(OBJ, [OBJ retain]);

#pragma mark - Debug
#ifdef DEBUG
#define DebugLog(MSG, ...) NSLog((@"%s:%d "MSG), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define DebugMark() DebugLog(@"called");
// outputs the specified code block (can be multi-line)
#define DebugCode(BLOCK) BLOCK
#else
#define DebugLog(MSG, ...) ;
#define DebugMark() ;
#define DebugCode(BLOCK) ;
#endif

#endif
