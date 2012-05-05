//
//  CBIntrospect.m
//  DCIntrospectDemo
//
//  Created by Christopher Bess on 5/2/12.
//  Copyright (c) 2012 Christopher Bess. All rights reserved.
//

#import "CBIntrospect.h"
#import "UIView+Introspector.h"
#import <sys/stat.h>
#import "JSONKit.h"

@interface CBIntrospect ()
{
    NSArray *_ignoreDumpSubviews;
}
- (void)sync;
@end

@implementation CBIntrospect
@synthesize syncFileSystemState = _syncFileSystemState;

- (id)init
{
    self = [super init];
    if (self) 
    {
        
    }
    return self;
}

#pragma mark - Properties

- (void)setSyncFileSystemState:(CBIntrospectSyncFileSystemState)syncFileSystemState
{
    _syncFileSystemState = syncFileSystemState;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sync) object:nil];
    
    switch (syncFileSystemState)
    {
        case CBIntrospectSyncFileSystemStarted:
            [self sync];
            break;
            
        case CBIntrospectSyncFileSystemStopped:
            [UIView unlinkView:self.currentView];
            break;
            
        default:
            break;
    }
}

#pragma mark - Sync

- (void)sync
{
    [self syncNow];
    
    // create the loop (polling the file system)
    if (self.syncFileSystemState == CBIntrospectSyncFileSystemStarted)
        [self performSelector:@selector(sync) withObject:nil afterDelay:0.3];
}

- (void)syncNow
{
    BOOL doSync = NO;
    // check the mod time
    const char *filepath = [[self.currentView syncFilePath] cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    if (stat(filepath, &sb) == 0)
    {
        doSync = (_lastModTime.tv_sec != sb.st_mtimespec.tv_sec);
    }
    
    if (doSync)
    {
        // get the view info
        NSError *error = nil;
        NSString *jsonString = [[NSString alloc] initWithContentsOfFile:[self.currentView syncFilePath]
                                                               encoding:NSUTF8StringEncoding
                                                                  error:&error];
        NSDictionary *jsonInfo = [jsonString objectFromJSONString];
        
        // if the mem address in the current view json is different, then point `self.currentView`
        // to the target memory address
        if (![self updateCurrentViewWithMemoryAddress:[jsonInfo valueForKey:kUIViewMemoryAddressKey]])
        { // the current view did not change, then update the current view
            // update the current view
            if ([self.currentView updateWithJSON:jsonInfo])
            {
                [self updateFrameView];
            }
        }
        
        [jsonString release];
    }
    
    // store last mod time
    _lastModTime = sb.st_mtimespec;
}

#pragma mark - Misc

- (BOOL)updateCurrentViewWithMemoryAddress:(NSString *)memAddress
{
    // if mem address different than current view, then get mem address of the target view
    if (![memAddress isEqualToString:self.currentView.memoryAddress])
    {
        // convert the memaddres to a pointer
        unsigned addr = 0;
        [[NSScanner scannerWithString:memAddress] scanHexInt:&addr];
        
        UIView *view = (id)addr;
        
        [self selectView:view];
        return YES;
    }
    
    return NO;
}

- (void)setupIgnoreDumpViews
{
    // an array of NSString objects that represent the class name of each
    // UIView class that will NOT be traversed during a view tree dump
    _ignoreDumpSubviews = [NSArray arrayWithObjects:
                           @"UISlider",
                           @"UITableViewCell",
                           nil];
}

#pragma mark - Overrides

- (void)onWillSelectView:(UIView *)view
{
    [super onWillSelectView:view];
    
    self.syncFileSystemState = CBIntrospectSyncFileSystemStopped;   
}

- (void)onDidSelectView:(UIView *)view
{
    [super onDidSelectView:view];
    
    if (view)
        self.syncFileSystemState = CBIntrospectSyncFileSystemStarted;
}

- (void)updateFrameView
{
    [super updateFrameView];
    
    if (self.on)
    {
        [UIView storeView:self.currentView];
    }
}

- (void)invokeIntrospector
{
    [super invokeIntrospector];
    
    if (self.on)
    {
        [self dumpWindowViewTree];
    }
    else
    {
        // remove the view tree json
        NSString *path = [[[DCUtility sharedInstance] cacheDirectoryPath] stringByAppendingPathComponent:kCBTreeDumpFileName];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

#pragma mark - Traverse Subviews

- (BOOL)canDumpView:(UIView *)view
{
    NSString *className = NSStringFromClass([view class]);
    if ([className hasPrefix:@"_"])
        return YES;
    return NO;
}

- (BOOL)canDumpSubviewsOfView:(UIView *)view
{
    NSString *className = NSStringFromClass([view class]);
    for (NSString *name in _ignoreDumpSubviews)
    {
        if ([name isEqualToString:className])
            return NO;
    }
    return YES;
}

- (void)dumpWindowViewTree
{
    NSMutableDictionary *treeDictionary = [self.mainWindow.dictionaryRepresentation mutableCopy];
    
    [self dumpSubviewsOfRootView:self.mainWindow toDictionary:treeDictionary];
    
    // write json to disk
    NSString *jsonString = [treeDictionary JSONString];
    NSString *path = [[[DCUtility sharedInstance] cacheDirectoryPath] stringByAppendingPathComponent:kCBTreeDumpFileName];
    [[DCUtility sharedInstance] writeString:jsonString toPath:path];
    [treeDictionary release];
}

- (void)dumpSubviewsOfRootView:(UIView *)rootView toDictionary:(NSMutableDictionary *)treeInfo
{
    NSMutableArray *viewArray = [NSMutableArray arrayWithCapacity:rootView.subviews.count];
    
    // traverse subviews
    for (UIView *view in rootView.subviews)
    {
        if ([self shouldIgnoreView:view])
            continue;
        
        if ([self canDumpView:view])
            continue;
        
        // add subview info to root view dictionary
        NSMutableDictionary *viewInfo = [view.dictionaryRepresentation mutableCopy];
        [viewArray addObject:viewInfo];
        
        if ([self canDumpSubviewsOfView:view])
            [self dumpSubviewsOfRootView:view toDictionary:viewInfo];
        
        [viewInfo release];
    }
    
    [treeInfo setObject:viewArray forKey:kUIViewSubviewsKey];
}
@end
