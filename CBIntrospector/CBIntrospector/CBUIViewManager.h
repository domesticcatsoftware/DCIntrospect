//
//  CBUIViewManager.h
//  CBIntrospector
//
//  Created by Christopher Bess on 5/2/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBUIView;
@protocol CBUIViewManagerDelegate;

@interface CBUIViewManager : NSObject
@property (nonatomic, assign) id<CBUIViewManagerDelegate> delegate;
@property (nonatomic, retain) CBUIView *currentView;
- (void)sync;
@end

@protocol CBUIViewManagerDelegate <NSObject>
- (void)viewManagerSavedViewToDisk:(CBUIViewManager *)manager;
- (void)viewManagerUpdatedViewFromDisk:(CBUIViewManager *)manager;
- (void)viewManagerClearedView:(CBUIViewManager *)manager;
@end
