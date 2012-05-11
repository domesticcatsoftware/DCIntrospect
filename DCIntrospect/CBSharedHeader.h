//
//  CBSharedConstants.h
//  DCIntrospectDemo
//
//  Created by Christopher Bess on 5/2/12.
//  Copyright (c) 2012 Christopher Bess. All rights reserved.
//

#ifndef CBIntrospector_CBSharedConstants_h
#define CBIntrospector_CBSharedConstants_h

static NSString *const kCBCurrentViewFileName = @"current.view.json";
static NSString * const kCBTreeDumpFileName = @"viewtree.dump.json";

// stored json keys
static NSString * const kUIViewSubviewsKey = @"subviews";
static NSString * const kUIViewClassNameKey = @"class";
static NSString * const kUIViewMemoryAddressKey = @"memaddress";
static NSString * const kUIViewHiddenKey = @"hidden";
static NSString * const kUIViewAlphaKey = @"alpha";
static NSString * const kUIViewBoundsKey = @"bounds";
static NSString * const kUIViewCenterKey = @"center";
static NSString * const kUIViewFrameKey = @"frame";
static NSString * const kUIViewDescriptionKey = @"viewdescription";

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
#define DLog NSLog
#define DebugLog(MSG, ...) NSLog((@"%s:%d "MSG), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define DebugMark() DebugLog(@"called");
// outputs the specified code block (can be multi-line)
#define DebugCode(BLOCK) BLOCK
#else
#define DLog(X, ...) ;
#define DebugLog ;
#define DebugMark() ;
#define DebugCode(BLOCK) ;
#endif

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
