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

- (void)dealloc
{
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
    NSString *syncFilePath = [self.currentView syncFilePath];
    if (!syncFilePath)
        return;
    
    if (self.currentView && ![[NSFileManager defaultManager] fileExistsAtPath:syncFilePath])
    {
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
        NSError *error = nil;
        NSString *jsonString = [[NSString alloc] initWithContentsOfFile:[self.currentView syncFilePath]
                                                               encoding:NSUTF8StringEncoding
                                                                  error:&error];
        NSDictionary *jsonInfo = [jsonString objectFromJSONString];
        
        // update the current view
        if ([self.currentView updateWithJSON:jsonInfo])
        {
            // success
            [self.delegate viewManagerUpdatedViewFromDisk:self];
        }
        
        [jsonString release];
    }
    
    // store last mod time
    _lastModTime = sb.st_mtimespec;
}

@end
