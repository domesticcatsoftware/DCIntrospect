//
//  CBWindow.m
//  CBIntrospector
//
//  Created by Christopher Bess on 5/2/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import "CBWindow.h"
#import "CBUIViewManager.h"
#import "CBUIView.h"
#import "JSONKit.h"

@interface CBWindow () <NSDraggingDestination, CBUIViewManagerDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate>
@property (assign) IBOutlet NSOutlineView *treeView;
@property (assign) IBOutlet NSButton *headerButton;
@property (assign) IBOutlet NSButton *hiddenSwitch;
@property (assign) IBOutlet NSSlider *alphaSlider;
@property (assign) IBOutlet NSTextField *heightTextField;
@property (assign) IBOutlet NSTextField *widthTextField;
@property (assign) IBOutlet NSTextField *topPositionTextField;
@property (assign) IBOutlet NSTextField *leftPositionTextField;
@property (nonatomic, readonly) CBUIViewManager *viewManager;
@property (nonatomic, copy) NSString *syncDirectoryPath;
- (void)loadCurrentViewControls;
@end

@implementation CBWindow
@synthesize treeView;
@synthesize headerButton;
@synthesize hiddenSwitch;
@synthesize alphaSlider;
@synthesize heightTextField;
@synthesize widthTextField;
@synthesize topPositionTextField;
@synthesize leftPositionTextField;
@synthesize viewManager = _viewManager;
@synthesize treeContents = _treeContents;
@synthesize syncDirectoryPath;

- (void)dealloc
{
    [_treeContents release];
    [_viewManager release];
    self.syncDirectoryPath = nil;
    [super dealloc];
}

#pragma mark - Properties

- (CBUIViewManager *)viewManager
{
    if (_viewManager == nil)
    {
        _viewManager = [CBUIViewManager new];
        _viewManager.delegate = self;
    }
    return _viewManager;
}

#pragma mark - General Overrides

- (void)awakeFromNib
{
	// user can drag a string to create a new note from the initially dropped data
	[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

- (BOOL)performKeyEquivalent:(NSEvent *)evt
{ // handles key down events
	int key = [evt keyCode];
    NSLog(@"main window key event: %d", key);
    
    switch (key)
    {
		case 36: // enter key
            break;
            
        // up/down arrow
        case 125:
        case 126:
            return NO;
    }
    
	int modFlag = [evt modifierFlags];
	if (modFlag & NSCommandKeyMask) switch (key)
	{		
		case 12: // Q (quit application)
            // confirm closing
            return NO;
            
		case 13: // W (close window)
            [self orderOut:nil];
            return YES;
    }
    
    return YES;
}

#pragma mark - Drag & Drop

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	NSPasteboard *paste = [sender draggingPasteboard];
	
	if ([[paste types] containsObject:NSFilenamesPboardType])
	{		
		// get the dragged file/dir path
		NSArray *files = [paste propertyListForType:NSFilenamesPboardType];	
        NSString *filePath = files.lastObject;
        
        BOOL isDir;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] && isDir)
        {
            self.syncDirectoryPath = filePath;
            
            // process file
            NSString *syncFilePath = [filePath stringByAppendingPathComponent:kCBCurrentViewFileName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:syncFilePath])
            {
                NSError *error = nil;
                NSString *jsonString = [NSString stringWithContentsOfFile:syncFilePath
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:&error];
                
                NSDictionary *jsonInfo = [jsonString objectFromJSONString];
                self.viewManager.currentView = [[CBUIView alloc] initWithJSON:jsonInfo];
                self.viewManager.currentView.syncFilePath = syncFilePath;
                [self.viewManager sync];
                
                [self loadCurrentViewControls];
            }
            
            [self reloadTree];
        }
        else
        {
            [[CBUtility sharedInstance] showMessageBoxWithString:NSLocalizedString(@"Unable to load a UIView from the directory.", nil)];
        }
    }
    
    return NO;
}

#pragma mark - Misc

- (void)loadCurrentViewControls
{
    CBUIView *view = self.viewManager.currentView;
    
    self.headerButton.title = nssprintf(@"<%@: 0x%@>", view.className, view.memoryAddress);
    
    self.leftPositionTextField.stringValue = nssprintf(@"%i", (int)NSMinX(view.frame));
    self.topPositionTextField.stringValue = nssprintf(@"%i", (int)NSMinY(view.frame));
    self.widthTextField.stringValue = nssprintf(@"%i", (int)NSWidth(view.frame));
    self.heightTextField.stringValue = nssprintf(@"%i", (int)NSHeight(view.frame));
    
    self.hiddenSwitch.state = view.hidden;
    self.alphaSlider.floatValue = view.alpha * 100;
}

- (void)reloadTree
{
    // load json dictionary from disk
    NSString *filePath = [self.syncDirectoryPath stringByAppendingPathComponent:kCBTreeDumpFileName];
    NSDictionary *treeInfo = [[CBUtility sharedInstance] dictionaryWithJSONFilePath:filePath];
    self.treeContents = treeInfo;
    [self.treeView reloadData];
}

#pragma mark - CBUIViewManagerDelegate

- (void)viewManagerSavedViewToDisk:(CBUIViewManager *)manager
{
    
}

- (void)viewManagerUpdatedViewFromDisk:(CBUIViewManager *)manager
{
    [self loadCurrentViewControls];
}

- (void)viewManagerClearedView:(CBUIViewManager *)manager
{
    self.leftPositionTextField.stringValue = self.topPositionTextField.stringValue = // below
    self.widthTextField.stringValue = self.heightTextField.stringValue = nil;
    
    self.alphaSlider.floatValue = 100;
    self.hiddenSwitch.state = NSOffState;
}

#pragma mark - NSOutlineDataSource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
        item = self.treeContents;
    
    return [[item valueForKey:kUIViewSubviewsKey] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (!item)
        item = self.treeContents;
    
    int count = [[item valueForKey:kUIViewSubviewsKey] count];
    return count != 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item)
        item = self.treeContents;
    
    NSArray *items = [item valueForKey:kUIViewSubviewsKey];
    return [items objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (!item)
        item = self.treeContents;
    
    NSString *name = [item valueForKey:kUIViewClassNameKey];
    if ([name hasPrefix:@"UI"])
        name = [name substringFromIndex:2];
    return name;
}
@end
