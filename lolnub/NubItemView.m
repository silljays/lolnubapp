//
//  NubItemView.m
//  lolnub
//
//  Created by Anonymous on 10/31/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//


#import "NubItemView.h"
#import "BotController.h"
#import "NSColor+Rainbows.h"

#define FUDGEY                              10.0

#define MIN_ITEM_CELL_WIDTH                 140.0
#define MIN_ITEM_CELL_HEIGHT                140.0
#define MIN_GRID_PADDING                    20.0
#define LABEL_GRID_PADDING                  40.0

#define ITEMVIEW_DISPLAY_INTERVAL           0.6

#define ITEMVIEW_PREVIEW_INTERVAL           3.0 * ITEMVIEW_DISPLAY_INTERVAL

#define ITEMVIEW_CACHE_INTERVAL             0.3

// TEMPORARY
#define AUX_VIEW_PADDING                    0.0
#define ITEM_PREVIEW_UPDATE_BATCH_COUNT     100


NSString *const NubItemViewSelectionDidChangeNotification = @"NubItemViewSelectionDidChangeNotification";

@interface NubItemView (Private)

- (CGFloat)x_gridHorizontalPadding;
- (CGFloat)x_gridVerticalPadding;

- (void)x_cacheItemGrid;
- (void)x_cacheItemPreviews;
- (void)x_clearItemPreviews;
- (void)x_startItemPreviewCache;

@end

@interface NubItemView () {}

@property (strong)      NSArray         *x_items;
@property (strong)      NubItemCell     *itemProtoCell;
@property (strong)      NSArray         *x_visibleItems;

@property               BOOL            isReloadingData;
@property               BOOL            isRefreshingItemPreviews;
@property               BOOL            isClearingItemPreviews;
@property               BOOL            shouldLoadIcons;
@property (nonatomic)   NSRange         visibleItemRange;
@property               NSRect          lastRect;

@property (strong)      NSTimer         *cacheTimer;
@end

@implementation NubItemView

@synthesize x_items;

@synthesize delegate, dataSource;
@synthesize itemProtoCell, isReloadingData;
@synthesize backgroundColor;
@synthesize x_visibleItems;

@synthesize isRefreshingItemPreviews;
@synthesize isClearingItemPreviews;
@synthesize shouldLoadIcons;

@synthesize dragging, lastDragPoint, dragRect;
@synthesize lastMouseDownPoint, lastMouseDownTime;
@synthesize selectedItems;

#pragma mark View

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    
    if (self) {
        // create the itemProtoCell prototype
        self.itemProtoCell = [[NubItemCell alloc] init];
        self.selectedItems = [NSMutableArray array];
        
        self.backgroundColor = [[NSColor blackColor] blendedColorWithFraction:0.1 ofColor:[NSColor darkGrayColor]];
        
        [self registerForDraggedTypes:@[NSFilenamesPboardType]];
        
        self.cacheTimer = [NSTimer scheduledTimerWithTimeInterval:ITEMVIEW_PREVIEW_INTERVAL target:self selector:@selector(display) userInfo:nil repeats:YES];
    }
    
    return self;
}

- (void)dealloc {
    @synchronized(self) {
        if (gridPoints) {
            free(gridPoints);
            gridPoints = NULL;
        }
        
    }
    
    [self.cacheTimer invalidate];
    [self unregisterDraggedTypes];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isFlipped {
    return YES;
}

- (BOOL)isOpaque {
    return NO;
}

- (BOOL)wantsDefaultClipping {
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    return YES;
}

- (BOOL)wantsLayer {
    return YES;
}

+ (BOOL)isCompatibleWithOverlayScrollers {
    return YES;
}

- (BOOL)allowsVibrancy {
    return YES;
}


#pragma mark Data

- (void)reloadData {
    DebugLog();
    
    self.isReloadingData = YES;
    self.shouldLoadIcons = NO;
    
    @synchronized(x_items) {
        // items + layout
        self.x_items = [self.dataSource items];

        // save a copy of the old selectedItems
        NSArray *selectedItemsStale = nil;
        
        selectedItemsStale = [selectedItems copy];
        [selectedItems removeAllObjects];
        
        self.shouldLoadIcons = YES;
        self.isReloadingData = NO;
        
        // get *new* selected items
        [x_items enumerateObjectsUsingBlock:^(id item, NSUInteger _index, BOOL *stop) {
            if ([selectedItemsStale containsObject:item]) {
                [selectedItems addObject:item];
            }
        }];
    }
    
    // reload the stufss
    [self reloadLayout];
}

- (void)reloadLayout {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    [self x_cacheItemGrid];
    [self x_cacheItemPreviews];
    
    [self setNeedsDisplay:YES];
}

#pragma mark Drawing

- (void)drawRect:(NSRect)cacheRect {
    //DebugLog();
    //NSLog(@"\t\t @itemCount:   %d", [self.dataSource itemsCount]);

    if (![NSThread isMainThread]) {
        return;
    }
    
    if (!NSEqualRects(cacheRect, self.lastRect)) {
        [self performSelectorOnMainThread:@selector(x_cacheItemGrid) withObject:nil waitUntilDone:YES];
    }

    NSGraphicsContext *graphics = [NSGraphicsContext currentContext];
    
    [graphics saveGraphicsState];
    graphics.imageInterpolation = NSImageInterpolationHigh;
    
    [self.backgroundColor set];
    [NSBezierPath fillRect:cacheRect];
    
    // find the visible points
    CGFloat iconSize                = [self.delegate previewSize];
    CGFloat halfIconSize            = iconSize / 2.0;
    CGFloat iconLabelPaddingSize    = iconSize + self.x_gridVerticalPadding;
    
    NSInteger firstVisibleIndex, lastVisibleIndex;
    
    // Find our visibleItems
    self.x_visibleItems = nil;
    
    // we need itemsCount to correctly calculate our visibleItemRange
    NSUInteger itemsCount = (self.x_items).count;
    
    // the first visible item will be above the .y of our dirty rect
    firstVisibleIndex = gridCols * floorf(cacheRect.origin.y / iconLabelPaddingSize);
    // the last item will be the offset of the first + the number of visible items
    lastVisibleIndex = firstVisibleIndex + (gridCols * ceilf(cacheRect.size.height / iconLabelPaddingSize));
    
    // ADD "PADDING" SO THAT ICON PREVIEWS ABOVE/BELOW OUR VISIBLE RECT WILL ALSO LOAD
    
    // add padding before and after the rect we draw for smooth icon preview caching
    firstVisibleIndex   -= gridCols * 3;
    lastVisibleIndex    += gridCols * 3;
    
    // FIX ANY POSSIBLE RANGE OVERFLOWS
    
    // if we are displaying the first few rows, reset the firstVisibleIndex to 0 to avoid range overflows
    if (firstVisibleIndex < 0) {
        firstVisibleIndex = 0;
    }
    
    // reset the "hard" lastVisibleIndex to either a full or partial row (e.g only the number of items left to display)
    if ((firstVisibleIndex + lastVisibleIndex) > itemsCount) {
        lastVisibleIndex = itemsCount - firstVisibleIndex;
    }
    else {
        lastVisibleIndex = lastVisibleIndex - firstVisibleIndex;
    }
    
    // overflow
    if (lastVisibleIndex > itemsCount) {
        lastVisibleIndex = itemsCount;
    }
    
    // what does the illusion show?
    self.visibleItemRange = NSMakeRange(firstVisibleIndex, lastVisibleIndex);
    self.x_visibleItems = [self.x_items subarrayWithRange:self.visibleItemRange];
    
    // capture our items and rects
    [self.x_visibleItems enumerateObjectsUsingBlock:^(NubItem *item, NSUInteger index, BOOL *stop) {
        // compute the geo
        NSPoint itemPoint = gridPoints[firstVisibleIndex + index];
        NSRect  itemRect  = NSMakeRect(itemPoint.x - halfIconSize, itemPoint.y - halfIconSize, iconSize, iconSize);
        
        // DRAW THE ITEMS WITH A PROTOTYPE FOR GREAT "CAPSLEVEL" SPEED
        itemProtoCell.iconCell.image = item.preview;
        
        // label
        itemProtoCell.labelCell.title = item.nubspace;
        [itemProtoCell.labelCell drawWithFrame:NSMakeRect(itemPoint.x - halfIconSize, itemPoint.y + halfIconSize, iconSize, iconSize) inView:self];

        if ([selectedItems containsObject:item]) {
            [[[NSColor prettyBlue] colorWithAlphaComponent:0.42] set];
            
            NSBezierPath *rectPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(itemRect, -10.0, 0.0) xRadius:2.0 yRadius:2.0];
            [rectPath fill];
        }
        
        
        // icon
        [itemProtoCell.iconCell  drawWithFrame:itemRect inView:self];
    }];
    
    // DRAW THE DRAGRECT
    if (!NSEqualRects(NSZeroRect, dragRect)) {
        NSBezierPath *dragPath = [NSBezierPath bezierPathWithRect:self.dragRect];
        [[[NSColor darkGrayColor] colorWithAlphaComponent:0.35] set];
        [dragPath fill];
        
        [[[NSColor whiteColor] colorWithAlphaComponent:0.89] set];
        [dragPath stroke];
    }
    
    // outer ring + shadow effect
    NSShadow *shadow = [[NSShadow alloc] init];
    
    shadow.shadowOffset = NSMakeSize(0.0, 22.0);
    shadow.shadowBlurRadius = 20.0;
    shadow.shadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.96];
    [shadow set];

    [[[[NSColor whiteColor] blendedColorWithFraction:0.12 ofColor:[NSColor prettyBlue]] colorWithAlphaComponent:0.22] set];
    [[NSBezierPath bezierPathWithRect:self.bounds] stroke];
    
    [graphics restoreGraphicsState];
    
    // update last *drawn* rect
    if (!NSEqualRects(cacheRect, self.lastRect)) {
        self.lastRect = cacheRect;
        
        [NSTimer scheduledTimerWithTimeInterval:ITEMVIEW_CACHE_INTERVAL target:self selector:@selector(x_cacheItemPreviews) userInfo:nil repeats:NO];
    }
}

- (void)viewDidEndLiveResize {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    [self reloadLayout];
}

- (void)setFrame:(NSRect)frameRect {
    super.frame = frameRect;
    
    [self x_cacheItemGrid];
}

#pragma mark UI

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)local {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    return [self.delegate draggingSourceOperationMaskForLocal:local];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    return [self.delegate draggingEntered:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    return [self.delegate performDragOperation:sender];
}

- (void)mouseDown:(NSEvent *)event {
    NSInteger modifierFlags = event.modifierFlags;
    
    // get the local point of the click
    NSPoint clickPoint = [self convertPoint:event.locationInWindow fromView:nil];
    // expand the clickPoint into an icon-sized clickRect
    CGFloat halfIconSize = [self.delegate previewSize] / 2.0;
    
    NSRect clickRect = NSMakeRect(clickPoint.x - halfIconSize, clickPoint.y - halfIconSize, halfIconSize * 2.0, halfIconSize * 2.0);
    
    // determine if an item was hit by the mouse
    __block NubItem *hitItem = nil;
    
    [self.x_items enumerateObjectsUsingBlock:^(id item, NSUInteger index, BOOL *stop) {
        if (NSPointInRect(gridPoints[index], clickRect)) {
            hitItem = item;
            *stop = YES;
        }
    }];
    
    // what (if any) modifiers are there?
    BOOL modifiersDown = (modifierFlags & NSShiftKeyMask || modifierFlags & NSCommandKeyMask);
    
    if (!hitItem) {
        // setup dragging variables
        self.dragging = YES;
        self.lastMouseDownPoint = NSZeroPoint;
        self.lastDragPoint = clickPoint;
        
        if (!modifiersDown) {
            [self.selectedItems removeAllObjects];
        }
    }
    else {
        // setup NO to dragging
        self.dragging = NO;
        self.lastDragPoint = NSZeroPoint;
        
        // event tracking
        NSTimeInterval eventTime, lastMouseTime, doubleClickTime, elapsedTime;
        
        eventTime		= event.timestamp;
        lastMouseTime	= self.lastMouseDownTime;
        doubleClickTime	= [NSEvent doubleClickInterval];
        elapsedTime		= eventTime - lastMouseTime;
        
        // click status and modifiers
        BOOL singleClick = ((elapsedTime > doubleClickTime) && (event.clickCount == 1));
        
        if (singleClick) {
            // single click
            if (selectedItems.count < 1) {
                // NO selection
                [selectedItems addObject:hitItem];
            }
            else {
                // with selection
                if (![selectedItems containsObject:hitItem]) {
                    // modifiers
                    if (!modifiersDown) {
                        [selectedItems removeAllObjects];
                    }
                    
                    // NO contain item
                    [selectedItems addObject:hitItem];
                }
                else {
                    // contains item
                    if (modifiersDown) {
                        [selectedItems removeObject:hitItem];
                    }
                }
            }
        }
        else {
            // double click
            if (selectedItems.count < 1) {
                // NO selection
                [selectedItems addObject:hitItem];
            }
            else {
                // with selection
                if (![selectedItems containsObject:hitItem]) {
                    // NO contain hit
                    if (!modifiersDown) {
                        // NO modifiers
                        [selectedItems removeAllObjects];
                    }
                    
                    // select the hitCell
                    [selectedItems addObject:hitItem];
                }
                else {
                    // contains hit
                    if (modifiersDown) {
                        // with modifiers
                        [selectedItems removeAllObjects];
                        
                        [selectedItems addObject:hitItem];
                    }
                }
            }
            
            // all double clicks open the selection in one way or another
            [self openSelected:self];
        }
        
        self.lastMouseDownPoint = clickPoint;
        self.lastMouseDownTime = event.timestamp;
    }
    
    // display to show any highlited rects
    [self setNeedsDisplay:YES];
}

- (void)rightMouseDown:(NSEvent *)event {
    // clear the mouse down tracking to prevent right clicks from triggering double-clicks
    self.lastMouseDownPoint = NSZeroPoint;
    self.lastMouseDownTime = 0;
    
    [super rightMouseDown:event];
    
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)event {
    [self setDragging:NO];
    self.dragRect = NSZeroRect;
    
    [super mouseUp:event];
    
    [self setNeedsDisplay:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NubItemViewSelectionDidChangeNotification object:self];
}

- (void)mouseDragged:(NSEvent *)event {
    // mouse point
    NSPoint currentPoint = [self convertPoint:event.locationInWindow fromView:nil];
    
    CGFloat iconSize        = [self.delegate previewSize];
    CGFloat halfIconSize    = iconSize / 2.0;
    
    // nothing to drag
    if (self.dragging) {
        [self.selectedItems removeAllObjects];
        
        NSPoint startPoint = self.lastDragPoint;
        
        NSRect newDragRect;
        
        // which origin to use
        if (currentPoint.x > startPoint.x) {
            newDragRect.origin.x = startPoint.x;
            newDragRect.size.width = currentPoint.x - startPoint.x;
        }
        else {
            newDragRect.origin.x = currentPoint.x;
            newDragRect.size.width = startPoint.x - currentPoint.x;
        }
        
        if (currentPoint.y > startPoint.y) {
            newDragRect.origin.y = startPoint.y;
            newDragRect.size.height = currentPoint.y - startPoint.y;
        }
        else {
            newDragRect.origin.y = currentPoint.y;
            newDragRect.size.height = startPoint.y - currentPoint.y;
        }
        self.dragRect = newDragRect;
        
        // create rects for each of our items
        [[self.x_items subarrayWithRange:self.visibleItemRange] enumerateObjectsUsingBlock:^(id item, NSUInteger index, BOOL *stop) {
            NSPoint itemPoint = gridPoints[index];
            NSRect itemRect = NSMakeRect(itemPoint.x - halfIconSize, itemPoint.y - halfIconSize, iconSize, iconSize);
            
            if (NSIntersectsRect(itemRect, newDragRect)) {
                if (item) {
                    if (![selectedItems containsObject:item]) {
                        [selectedItems addObject:item];
                    }
                }
            }
        }];
    }
    else {
        NSSize frameSize = self.frame.size;
        
        // collect the selectedCells file paths
        NSMutableArray *dragPaths = [NSMutableArray array];
        
        // create our image and lockFocus to draw the nodeCells
        NSImage *dragImage = [[NSImage alloc] initWithSize:frameSize];
        [dragImage lockFocusFlipped:self.flipped];
        
        [NSGraphicsContext currentContext].imageInterpolation = NSImageInterpolationHigh;
        
        [[self.x_items subarrayWithRange:self.visibleItemRange] enumerateObjectsUsingBlock:^(NubItem *item, NSUInteger index, BOOL *stop) {
            if (item) {
                if ([self.selectedItems containsObject:item]) {
                    NSPoint itemPoint = gridPoints[index];
                    NSRect itemRect = NSMakeRect(itemPoint.x - halfIconSize, itemPoint.y - halfIconSize, iconSize, iconSize);
                    
                    itemProtoCell.iconCell.image = item.preview;
                    itemProtoCell.labelCell.title = item.nubspace;
                    
                    [itemProtoCell.iconCell drawWithFrame:itemRect inView:self];
                    
                    // add the cell's path to filePaths
                    [dragPaths addObject:item.path];
                }
            }
        }];
        
        [dragImage unlockFocus];
        
        // Write data to the pasteboard
        NSPasteboard *pasteBoard = [NSPasteboard pasteboardWithName:NSDragPboard];
        
        [pasteBoard declareTypes:@[NSFilenamesPboardType] owner:self];
        [pasteBoard setPropertyList:dragPaths forType:NSFilenamesPboardType];
        
        // set the dragging image
        [self dragImage:dragImage at:NSMakePoint(0.0, frameSize.height) offset:NSZeroSize event:event pasteboard:pasteBoard source:self slideBack:YES];
        
        [super mouseDragged:event];
    }
    
    [self autoscroll:event];
    [self setNeedsDisplay:YES];
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
    if (![delegate respondsToSelector:@selector(menuForEvent:)]) {
        return nil;
    }
    
    return [self.delegate menuForEvent:event];
}

- (void)keyDown:(NSEvent *)event {
    if ([event.charactersIgnoringModifiers isEqualToString:@" "]) {
        if (selectedItems.count) {
            [self openSelected:self];
        }
        else {
            if (event.modifierFlags & NSCommandKeyMask) {
                [self.enclosingScrollView pageUp:self];
            }
            else {
                [self.enclosingScrollView pageDown:self];
            }
        }
    }
}

- (void)keyUp:(NSEvent *)event {
    
}

#pragma mark Actions

- (void)selectAll:(id)sender {
    [self.selectedItems addObjectsFromArray:self.x_items];
    
    [self setNeedsDisplay:YES];
}

- (void)openSelected:(id)sender {
    [self.delegate openSelectedItems:self];
    
    [self setNeedsDisplay:YES];
}

@end


@implementation NubItemView (Private)

- (CGFloat)x_gridHorizontalPadding {
    NSRect frameRect    = self.frame;
    
    CGFloat iconSize    = [self.delegate previewSize];
    CGFloat colsSize    = floorf(frameRect.size.width / (iconSize + MIN_GRID_PADDING));
    
    return (frameRect.size.width - (colsSize * iconSize)) / colsSize;
}

- (CGFloat)x_gridVerticalPadding {
    return MIN_GRID_PADDING + LABEL_GRID_PADDING;
}

- (void)x_cacheItemGrid {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    // 1) CALCULATE THE GRID POINT ARRAY
    CGFloat iconSize            = [self.delegate previewSize];
    CGFloat halfIconSize        = (iconSize / 2.0);
    
    CGFloat horizontalPadding   = self.x_gridHorizontalPadding;
    CGFloat verticalPadding     = self.x_gridVerticalPadding;
    
    NSUInteger  itemsCount      = self.x_items.count;
    NSRect      boundsRect      = self.bounds;
    
    NSPointArray newPoints      = NULL;
    NSInteger    newCols;
    NSInteger    newRows;
    
    // set new counts
    if (!itemsCount || (boundsRect.size.width < MIN_ITEM_CELL_WIDTH || boundsRect.size.height < MIN_ITEM_CELL_HEIGHT)) {
        newCols = 0;
        newRows = 0;
    }
    else {
        newCols = (NSInteger)floorf(boundsRect.size.width / (iconSize + horizontalPadding));
        newRows = (NSInteger)ceilf((float)itemsCount / (float)newCols);
    }
    
    if (newCols == 0 && newRows == 0) {
        newPoints = (NSPointArray)malloc(1 * sizeof(NSPoint));
    }
    else {
        // raw arrays are much faster than boxing NSValues
        newPoints = (NSPointArray)malloc((newRows * newCols) * sizeof(NSPoint));
    }
    
    // map all possible grid points
    
    CGFloat startX = (horizontalPadding / 2) + boundsRect.origin.x + halfIconSize;
    CGFloat startY = boundsRect.origin.y + (verticalPadding) + (iconSize / 2.0) + AUX_VIEW_PADDING;
    
    CGFloat nextX = 0;
    CGFloat nextY = startY;
    
    NSInteger i = 0;
    NSInteger j = 0;
    NSInteger k = 0;
    
    // iterate from top-to-bottom (we're a flipped view)
    for(i = 0; i < newRows; i++) {
        // reset x axis
        nextX = startX;
        
        for(j = 0; j < newCols; j++) {
            // store this space into the grid
            newPoints[k] = NSMakePoint(nextX, nextY);
            
            nextX += iconSize + horizontalPadding;
            
            k++;
        }
        
        nextY += iconSize + verticalPadding;
    }
    
    @synchronized(self) {
        // clear existing gridPoints
        if (gridPoints) {
            free(gridPoints);
            gridPoints = NULL;
        }
        
        gridPoints = newPoints;
        gridCols   = newCols;
        gridRows   = newRows;
    }
    
    // make our best frame size
    NSRect visibleRect = self.enclosingScrollView.visibleRect;
    NSSize bestFrameSize = NSMakeSize(visibleRect.size.width, (AUX_VIEW_PADDING * 2) + verticalPadding + ((iconSize + verticalPadding) * newRows));
    
    // resize our bestFrameSize if it is shorter than the current size
    if (visibleRect.size.height > bestFrameSize.height) {
        bestFrameSize.height = visibleRect.size.height;
    }
    
    [self setFrameSize:bestFrameSize];
}

- (void)x_cacheItemPreviews {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    if (self.isRefreshingItemPreviews) {
        return;
    }
    
    [self performSelectorInBackground:@selector(x_startItemPreviewCache) withObject:nil];
}

- (void)x_startItemPreviewCache {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    if ([NSThread isMainThread]) {
        return;
    }
    
    self.isRefreshingItemPreviews = YES;
    
    CGFloat iconSize = [self.delegate previewSize];
    
    @synchronized(x_items) {
        [self.x_visibleItems enumerateObjectsUsingBlock:^(NubItem *item, NSUInteger index, BOOL *shouldStop) {
            [item refreshPreviewOfSize:iconSize completionBlock:NULL];
        }];
    }
    
    // render
    [self performSelectorOnMainThread:@selector(displayIfNeeded) withObject:nil waitUntilDone:YES];
    self.isRefreshingItemPreviews = NO;
}

- (void)x_clearItemPreviews {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
//    @synchronized(x_items) {
//        [self.x_items enumerateObjectsUsingBlock:^(NubItem *item, NSUInteger index, BOOL *stop) {
//            @try {
//                NSPoint itemPoint = gridPoints[index];
//                
//                if (!NSPointInRect(itemPoint, self.visibleRect)) {
//                    [item clearPreview];
//                }
//            }
//            @catch (NSException *exception) { /* noop */ }
//        }];
//    }
//    
//    [self performSelectorOnMainThread:@selector(displayIfNeeded) withObject:nil waitUntilDone:YES];
}

@end

