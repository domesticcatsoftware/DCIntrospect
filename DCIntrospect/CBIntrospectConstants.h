//
//  CBConstants.h
//  CBIntrospector
//
//  Created by Christopher Bess on 5/12/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#ifndef CBIntrospector_CBConstants_h
#define CBIntrospector_CBConstants_h

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

#endif
