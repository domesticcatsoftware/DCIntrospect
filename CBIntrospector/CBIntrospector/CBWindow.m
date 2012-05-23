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
#import "CBTreeView.h"

static NSString * const kCBUserSettingShowAllSubviewsKey = @"show-subviews";

@interface CBWindow () <NSDraggingDestination, CBUIViewManagerDelegate, NSOutlineViewDataSource, 
    NSOutlineViewDelegate, NSTextFieldDelegate, NSWindowDelegate, NSSplitViewDelegate>
@property (assign) IBOutlet NSMenuItem *showAllSubviewsMenuItem;
@property (assign) IBOutlet NSTextView *textView;
@property (assign) IBOutlet NSSplitView *splitView;
@property (assign) IBOutlet CBTreeView *treeView;
@property (assign) IBOutlet NSButton *headerButton;
@property (assign) IBOutlet NSButton *hiddenSwitch;
@property (assign) IBOutlet NSSlider *alphaSlider;
@property (assign) IBOutlet NSTextField *heightTextField;
@property (assign) IBOutlet NSTextField *widthTextField;
@property (assign) IBOutlet NSTextField *topPositionTextField;
@property (assign) IBOutlet NSTextField *leftPositionTextField;
@property (nonatomic, readonly) CBUIViewManager *viewManager;
@property (nonatomic, readonly) NSString *syncDirectoryPath;
@property (nonatomic, assign) NSTextField *focusedTextField;
@property (nonatomic, assign) BOOL showAllSubviews;
- (IBAction)treeNodeClicked:(id)sender;
- (void)loadCurrentViewControls;
@end

@implementation CBWindow
@synthesize showAllSubviewsMenuItem;
@synthesize textView;
@synthesize splitView;
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
@synthesize focusedTextField;
@synthesize showAllSubviews = _showAllSubviews;

- (void)dealloc
{
    [_treeContents release];
    [_viewManager release];
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

- (NSString *)syncDirectoryPath
{
    return self.viewManager.syncDirectoryPath;
}

- (BOOL)showAllSubviews
{
    return (_showAllSubviews = [[NSUserDefaults standardUserDefaults] boolForKey:kCBUserSettingShowAllSubviewsKey]);
}

- (void)setShowAllSubviews:(BOOL)show
{
    _showAllSubviews = show;
    [[NSUserDefaults standardUserDefaults] setBool:show forKey:kCBUserSettingShowAllSubviewsKey];
}

#pragma mark - General Overrides

- (void)awakeFromNib
{
    self.showAllSubviewsMenuItem.state = (self.showAllSubviews ? NSOnState : NSOffState);
    
	// user can drag a string to create a new note from the initially dropped data
	[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [self.splitView setPosition:500 ofDividerAtIndex:0];
    [self.splitView adjustSubviews];
    
    // setup text view
    self.textView.font = [NSFont fontWithName:@"Monaco" size:12];
    self.textView.textContainer.containerSize = NSMakeSize(FLT_MAX, FLT_MAX);
    self.textView.textContainer.widthTracksTextView = NO;
    [self.textView setHorizontallyResizable:YES];
}

- (BOOL)performKeyEquivalent:(NSEvent *)evt
{ // handles key down events
	int key = [evt keyCode];
	int modFlag = [evt modifierFlags];
//    NSLog(@"main window key event: %d", key);
    BOOL shiftKey = (modFlag | NSShiftKeyMask);
    
    // ignore keys from the tree view
    if (self.treeView == self.firstResponder)
    {
        switch (key)
        {
            //case 49: // space
            case 36: // enter
                [self reselectCurrentlySelectedNode];
                break;
        }
        
        return NO;
    }
    
    switch (key)
    {
		case 36: // enter key
            break;
            
        // arrow keys
        case 125: // down
            [[CBUtility sharedInstance] updateIntValueWithTextField:self.focusedTextField addValue:(shiftKey ? -10 : -1)];
            [self controlTextDidChange:[NSNotification notificationWithName:NSControlTextDidChangeNotification object:self.focusedTextField]];
            return YES;
            
        case 126: // up
            [[CBUtility sharedInstance] updateIntValueWithTextField:self.focusedTextField addValue:(shiftKey ? 10 : 1)];
            [self controlTextDidChange:[NSNotification notificationWithName:NSControlTextDidChangeNotification object:self.focusedTextField]];
            return YES;
    }
    
	if (modFlag | NSCommandKeyMask) switch (key)
	{		
		case 12: // Q (quit application)
            // confirm closing
            return NO;
            
		case 13: // W (close window)
            [self orderOut:nil];
            return YES;
    }
    
    return NO;
}

#pragma mark - Drag & Drop

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    return NSDragOperationLink;
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
            self.viewManager.syncDirectoryPath = filePath;
            
            // process file
            NSString *syncFilePath = [filePath stringByAppendingPathComponent:kCBCurrentViewFileName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:syncFilePath])
            {
                NSError *error = nil;
                NSString *jsonString = [NSString stringWithContentsOfFile:syncFilePath
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:&error];
                
                NSDictionary *jsonInfo = [jsonString objectFromJSONString];
                [self loadControlsWithJSON:jsonInfo];
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

#pragma mark - Events

- (IBAction)alphaSliderChanged:(id)sender 
{
    self.viewManager.currentView.alpha = self.alphaSlider.floatValue / 100;
}

- (IBAction)hiddenSwitchChanged:(id)sender 
{
    self.viewManager.currentView.hidden = self.hiddenSwitch.state;
}

- (IBAction)treeNodeClicked:(id)sender 
{
    [self reselectCurrentlySelectedNode];
}

- (IBAction)headerButtonClicked:(id)sender 
{
    if (self.viewManager.currentView)
    {
        [self.treeView reloadData];
        [self expandViewTree];
        
        [self selectTreeItemWithMemoryAddress:self.viewManager.currentView.memoryAddress];
    }
}

// menu item action
- (IBAction)reloadViewTreeClicked:(id)sender 
{
    [self reloadTree];
}

- (IBAction)showAllSubviewsClicked:(id)sender 
{
    self.showAllSubviews = !self.showAllSubviews;
    self.showAllSubviewsMenuItem.state = (self.showAllSubviews ? NSOnState : NSOffState);
    
    [self reloadTree];
}

#pragma mark - Misc

- (void)expandViewTree
{
    // expand it all to allow the 'walking' tree logic to work as expected, being able to find/select any node
    [self.treeView expandItem:[self.treeView itemAtRow:0] expandChildren:YES];
}

- (void)reselectCurrentlySelectedNode
{
    NSDictionary *viewInfo = [self.treeView itemAtRow:self.treeView.selectedRow];
    DebugLog(@"selected: %@", [viewInfo valueForKey:kUIViewClassNameKey]);
    [self loadControlsWithJSON:viewInfo];
}

- (void)loadControlsWithJSON:(NSDictionary *)jsonInfo
{
    self.viewManager.currentView = [[CBUIView alloc] initWithJSON:jsonInfo];
    self.viewManager.currentView.syncFilePath = [self.syncDirectoryPath stringByAppendingPathComponent:kCBCurrentViewFileName];
    
    [self.viewManager.currentView saveJSON];
    [self.viewManager sync];
    
    [self loadCurrentViewControls];
}

- (void)loadCurrentViewControls
{
    CBUIView *view = self.viewManager.currentView;
    
    self.headerButton.title = nssprintf(@"<%@: 0x%@>", view.className, view.memoryAddress);
    if (view.viewDescription)
        self.textView.string = view.viewDescription;
    
    self.leftPositionTextField.stringValue = nssprintf(@"%i", (int)NSMinX(view.frame));
    self.topPositionTextField.stringValue = nssprintf(@"%i", (int)NSMinY(view.frame));
    self.widthTextField.stringValue = nssprintf(@"%i", (int)NSWidth(view.frame));
    self.heightTextField.stringValue = nssprintf(@"%i", (int)NSHeight(view.frame));
    
    self.hiddenSwitch.state = view.hidden;
    self.alphaSlider.floatValue = view.alpha * 100;
}

- (void)reloadTree
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.syncDirectoryPath])
    {
        NSString *msg = [@"Unable to reload the tree.\nCheck path: " stringByAppendingString:self.syncDirectoryPath ?: @"None"];
        [[CBUtility sharedInstance] showMessageBoxWithString:msg];
        return;
    }
    
    // load json dictionary from disk
    NSString *filePath = [self.syncDirectoryPath stringByAppendingPathComponent:kCBTreeDumpFileName];
    NSDictionary *treeInfo = [[CBUtility sharedInstance] dictionaryWithJSONFilePath:filePath];
    self.treeContents = treeInfo;
    [self.treeView reloadData];
    
    [self expandViewTree];
}

- (BOOL)allowChildrenWithJSON:(NSDictionary *)jsonInfo
{
    if (_showAllSubviews)
        return YES;
    
    NSString *className = [jsonInfo valueForKey:kUIViewClassNameKey];
    
    // don't allow below class to be branches
    static NSMutableArray *items = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        items = [[NSMutableArray alloc] initWithObjects:
                 @"UITableViewCell",
                 @"UISegmentedControl",
                 @"UISlider",
                 @"UIPageControl",
                 @"UITextField",
                 @"UIProgressView",
                 @"UIActivityIndicatorView",
                 nil];
    });
    
    // try to find the class name
    for (NSString *name in items)
    {
        if ([name isEqualToString:className])
            return NO;
    }
    
    return YES;
}

#pragma mark - Find in tree

- (NSDictionary *)itemFromJSON:(NSDictionary *)jsonInfo withMemoryAddress:(NSString *)memAddress
{
    if ([[jsonInfo valueForKey:kUIViewMemoryAddressKey] isEqualToString:memAddress])
        return jsonInfo;
    
    // check the subviews
    NSArray *subviewsInfo = [jsonInfo valueForKey:kUIViewSubviewsKey];
    for (NSDictionary *subviewInfo in subviewsInfo)
    {
        NSDictionary *info = [self itemFromJSON:subviewInfo withMemoryAddress:memAddress];
        if (info)
            return info;
    }
    
    return nil;
}

- (void)selectTreeItemWithMemoryAddress:(NSString *)memAddress
{
    // traverse tree
    NSDictionary *itemInfo = [self itemFromJSON:self.treeContents withMemoryAddress:memAddress];
    if (itemInfo == nil)
        return;
    
    int nRow = [self.treeView rowForItem:itemInfo];
    
    if (nRow < 0) 
    {
        // remove selection
        [self.treeView deselectRow:self.treeView.selectedRow];
        return;
    }
    
    // expand its parent to make sure it is visible
    NSDictionary *parentInfo = [self.treeView parentForItem:itemInfo];
    [self.treeView expandItem:parentInfo];
    
    // select it
    [self.treeView selectRowIndexes:[NSIndexSet indexSetWithIndex:nRow] byExtendingSelection:NO];
    
    [self.treeView scrollRowToVisible:nRow];
}

#pragma mark - CBUIViewManagerDelegate

- (void)viewManagerSavedViewToDisk:(CBUIViewManager *)manager
{
    
}

// typically called when the user selects a view in the simulator
- (void)viewManagerUpdatedViewFromDisk:(CBUIViewManager *)manager
{
    [self loadCurrentViewControls];
    
    // locate the view in the tree
    [self selectTreeItemWithMemoryAddress:manager.currentView.memoryAddress];
}

- (void)viewManagerClearedView:(CBUIViewManager *)manager
{
    [self.headerButton setTitle:@"CBIntrospector"];
    self.leftPositionTextField.stringValue = self.topPositionTextField.stringValue = // below
    self.widthTextField.stringValue = self.heightTextField.stringValue = @"";
    
    self.alphaSlider.floatValue = 100;
    self.hiddenSwitch.state = NSOffState;
    self.textView.string = @"";
    
    // clear tree view
    self.treeContents = nil;
    [self.treeView reloadData];
}

#pragma mark - NSOutlineDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
        item = self.treeContents;
    
    if (![self allowChildrenWithJSON:item])
        return 0;
    
    return [[item valueForKey:kUIViewSubviewsKey] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (!item)
        item = self.treeContents;
    
    if (![self allowChildrenWithJSON:item])
        return NO;
    
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
    // not needed, the view is setup in [outlineView:willDisplayCell:...]
    return nil;
}

#pragma mark - NSOutlineViewDelegate

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    NSDictionary *jsonInfo = item;
    NSButtonCell *buttonCell = cell;
    
    // get the name
    NSString *name = [jsonInfo valueForKey:kUIViewClassNameKey];
    if ([name hasPrefix:@"UI"])
        name = [name substringFromIndex:2]; // remove the class prefix
    
    // get the image
    NSString *imageName = @"NSView.icns";
    
    [buttonCell setTitle:name];
    [buttonCell setImage:[NSImage imageNamed:imageName]];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    [self reselectCurrentlySelectedNode];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return YES;
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification
{
    NSTextField *textField = notification.object;
    CBUIView *view = self.viewManager.currentView;
    NSRect frame = view.frame;
    
    if (self.leftPositionTextField == textField)
    {
        frame.origin.x = textField.intValue;
    }
    else if (self.topPositionTextField == textField)
    {
        frame.origin.y = textField.intValue;
    }
    else if (self.widthTextField == textField)
    {
        frame.size.width = textField.intValue;
    }
    else if (self.heightTextField == textField)
    {
        frame.size.height = textField.intValue;
    }
    
    view.frame = frame;
}

- (void)controlDidBecomeFirstResponder:(NSResponder *)responder
{
    self.focusedTextField = (NSTextField*) responder;
}

#pragma mark - NSSplitView Delegate

#if 0
- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
{
    return 450;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
    return NO;
}
#endif
@end
