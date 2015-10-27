//
//  NubItemView.h
//  lolnub
//
//  Created by Anonymous on 10/31/13.
//  Copyright (c) 2014 lolnub.com developers All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NubItem.h"
#import "NubItemCell.h"

extern NSString *const NubItemViewSelectionDidChangeNotification;

@interface NubItemView : NSView {
    NSPointArray	gridPoints;
    NSInteger		gridCols;
    NSInteger		gridRows;
}

@property (weak)                IBOutlet id         delegate;
@property (nonatomic, weak)     IBOutlet id         dataSource;

@property (strong)              NSColor             *backgroundColor;

@property                       BOOL                dragging;
@property                       NSPoint             lastDragPoint;
@property                       NSRect              dragRect;
@property                       NSPoint             lastMouseDownPoint;
@property                       NSTimeInterval      lastMouseDownTime;

@property (strong)              NSMutableArray      *selectedItems;

// reset the entire view
- (void)reloadData;
// reset just the visual aspects of the view (ie. grid/icons)
- (void)reloadLayout;

// select all items
- (void)selectAll:(id)sender;
- (void)openSelected:(id)sender;

@end

@protocol NubItemViewDataSource

// the items a view should render
- (NSArray *)items;

// how many pixels the items should be previewed at
- (CGFloat)previewSize;

@optional

- (void)openSelectedItems:(id)sender;

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)local;

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;

@end
