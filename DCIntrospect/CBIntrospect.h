//
//  CBIntrospect.h
//  DCIntrospectDemo
//
//  Created by Christopher Bess on 5/2/12.
//  Copyright (c) 2012 Christopher Bess of Quantum Quinn. All rights reserved.
//

#import "DCIntrospect.h"
#import <time.h>

// Specifies the current state of the file system sync
typedef enum {
    // Sync has been activated
    CBIntrospectSyncFileSystemStarted,
    // Sync is no longer active
    CBIntrospectSyncFileSystemStopped,
} CBIntrospectSyncFileSystemState;

@interface CBIntrospect : DCIntrospect {
    struct timespec _lastModTime;
}

@property (nonatomic, assign) CBIntrospectSyncFileSystemState syncFileSystemState;

/**
 * Syncs the changes from the file system back to the corresponding iOS view.
 */
- (void)syncNow;
@end
