//
//  CBProjectWindow.m
//  CBIntrospector
//
//  Created by Christopher Bess on 6/4/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import "CBProjectWindow.h"
#import "CBPathItem.h"
#import "CBIntrospectorWindow.h"

@interface CBProjectWindow () <NSOutlineViewDataSource>
@property (assign) IBOutlet NSOutlineView *outlineView;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet CBIntrospectorWindow *introspectorWindow;
@property (nonatomic, readonly) NSRegularExpression *versionRegex;
@property (nonatomic, strong) NSArray *pathItems;
@end

@implementation CBProjectWindow
@synthesize outlineView;
@synthesize progressIndicator;
@synthesize introspectorWindow;
@synthesize pathItems = _pathItems;
@synthesize versionRegex = _versionRegex;

- (void)dealloc
{
    NSRelease(_versionRegex)
    NSRelease(_pathItems)
    [super dealloc];
}

- (NSRegularExpression *)versionRegex
{
    if (_versionRegex == nil)
        _versionRegex = [[NSRegularExpression alloc] initWithPattern:@"[0-9]\\.[0-9]" options:0 error:nil];
    return _versionRegex;
}

#pragma mark - Misc

- (BOOL)textIsVersionString:(NSString *)string
{
    NSArray *matches = [self.versionRegex matchesInString:string options:NSMatchingCompleted range:NSMakeRange(0, string.length)];
    return (matches.count != 0);
}

- (void)reloadTree
{
    NSRegularExpression *guidRegex = [NSRegularExpression regularExpressionWithPattern:@"([A-Z0-9]{8})-([A-Z0-9]{4})-([A-Z0-9]{4})-([A-Z0-9]{4})-([A-Z0-9]{12})"
                                                                               options:0 error:nil];
    // build the path items collection
    NSArray *pathItems = [CBPathItem pathItemsAtPath:[[CBUtility sharedInstance] simulatorDirectoryPath] recursive:YES block:^BOOL(CBPathItem *item) {
        NSRange nameRange = NSMakeRange(0, item.name.length);
        BOOL isDir;
        if ([item.name hasSuffix:@".app"])
            return YES;
        else if ([item.name isEqualToString:@"Applications"])
            return YES;
        else if ([self textIsVersionString:item.name]
                 && ([[NSFileManager defaultManager] fileExistsAtPath:item.path isDirectory:&isDir] && isDir))
            return YES;
        else if ([guidRegex matchesInString:item.name options:NSMatchingCompleted range:nameRange].count)
            return YES;
        
        return NO; 
    }];
    
    self.pathItems = pathItems;
    [self.outlineView reloadData];
    
    DebugLog(@"%lu top level path items", pathItems.count);
}

#pragma mark - Events

- (IBAction)reloadButtonClicked:(id)sender 
{
    [self reloadTree];
}

#pragma mark - Outline Datasource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)theItem
{
    if (theItem == nil)
    {
        return self.pathItems.count;
    }
    
    CBPathItem *item = theItem;
    if ([self textIsVersionString:item.name])
    {
        NSArray *appDirItems = item.subItems;
        CBPathItem *appDirItem = appDirItems.lastObject;
        return appDirItem.subItems.count;   
    }
    
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (item == nil)
        return YES;
    return [self textIsVersionString:[item name]];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)theItem
{
    if (theItem == nil)
    {
        return [self.pathItems objectAtIndex:index];
    }
    
    CBPathItem *item = theItem;
    if ([self textIsVersionString:item.name])
    {
        NSArray *appDirItems = item.subItems;
        CBPathItem *appDirItem = appDirItems.lastObject;
        CBPathItem *guidItem = [appDirItem.subItems objectAtIndex:index];
        NSArray *appItems = guidItem.subItems;
        return appItems.lastObject;
    }
    
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    CBPathItem *pathItem = item;
    return pathItem.name;
}
@end
