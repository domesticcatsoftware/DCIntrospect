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
- (void)sync;
@end

@implementation CBIntrospect
@synthesize syncFileSystemState = _syncFileSystemState;

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
    const char *filepath = [[self.currentView syncFilePath] cStringUsingEncoding:NSASCIIStringEncoding];
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
        
        // update the current view
        if ([self.currentView updateWithJSON:jsonInfo])
        {
            [self updateFrameView];
        }
        
        [jsonString release];
    }
    
    // store last mod time
    _lastModTime = sb.st_mtimespec;
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
@end
