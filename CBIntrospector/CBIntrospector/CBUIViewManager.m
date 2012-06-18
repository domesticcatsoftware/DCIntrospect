//
//  CBUIViewManager.m
//  CBIntrospector
//
//  Created by Christopher Bess on 5/2/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import "CBUIViewManager.h"
#import "JSONKit.h"
#import <sys/stat.h>
#import "CBUIView.h"

@interface CBUIViewManager ()
{
    struct timespec _lastModTime;
}
- (void)syncNow;
@end

@implementation CBUIViewManager
@synthesize currentView;
@synthesize delegate;
@synthesize syncDirectoryPath;

- (void)dealloc
{
    self.syncDirectoryPath = nil;
    self.currentView = nil;
    self.delegate = nil;
    [super dealloc];
}

- (void)sync
{
    [self syncNow];
    
    // create the loop (polling the file system)
    [self performSelector:@selector(sync) withObject:nil afterDelay:0.3];
}

- (void)syncNow
{
    BOOL doSync = NO;
    NSString *syncFilePath = [self.syncDirectoryPath stringByAppendingPathComponent:kCBCurrentViewFileName];
    if (!syncFilePath)
        return;
    
    if (self.currentView 
        // no current view
        && ![[NSFileManager defaultManager] fileExistsAtPath:syncFilePath]
        // no tree view
        && ![[NSFileManager defaultManager] fileExistsAtPath:[self.syncDirectoryPath stringByAppendingPathComponent:kCBTreeDumpFileName]])
    {
        DebugLog(@"Cleared current view");
        self.currentView = nil;
        [self.delegate viewManagerClearedView:self];
        return;
    }
    
    // check the mod time
    const char *filepath = [syncFilePath cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    if (stat(filepath, &sb) == 0)
    {
        doSync = (_lastModTime.tv_sec != sb.st_mtimespec.tv_sec);
    }
    
    if (self.currentView.isDirty)
    {
        if ([self.currentView saveJSON])
        {
            // success
            [self.delegate viewManagerSavedViewToDisk:self];
        }
    }
    else if (doSync)
    {
        // get the view info
        NSDictionary *jsonInfo = [[CBUtility sharedInstance] dictionaryWithJSONFilePath:syncFilePath];
        
        // if no current view, then load it
        if (self.currentView == nil)
        {
            self.currentView = [[[CBUIView alloc] initWithJSON:jsonInfo] autorelease];
            
            if (self.currentView)
                [self.delegate viewManagerUpdatedViewFromDisk:self];
        } 
        // update the current view
        else if ([self.currentView updateWithJSON:jsonInfo])
        {
            // success
            [self.delegate viewManagerUpdatedViewFromDisk:self];
        }
    }
    
    // store last mod time
    _lastModTime = sb.st_mtimespec;
}

@end
