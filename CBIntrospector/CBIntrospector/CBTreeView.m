//
//  CBTreeView.m
//  CBIntrospector
//
//  Created by Christopher Bess on 5/9/12.
//  Copyright (c) 2012 C. Bess. All rights reserved.
//

#import "CBTreeView.h"

@implementation CBTreeView
- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
    NSRange visibleRowIndexes = [self rowsInRect:clipRect];
    NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
    int nRow = visibleRowIndexes.location;
    int nEndRow = nRow + visibleRowIndexes.length;
    
    NSColor *color = [NSColor colorWithCalibratedRed:0.929 green:0.953 blue:0.996 alpha:1.0];
    [color set];
    
    // draw highlight for the visible, selected rows
    for ( ; nRow < nEndRow; ++nRow)
    {
        if([selectedRowIndexes containsIndex:nRow])
        {
            NSRect aRowRect = NSInsetRect([self rectOfRow:nRow], 2, 1);
            NSRectFill(aRowRect);
        }
    }
}
@end
