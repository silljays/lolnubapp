//
//  NubModeController.m
//  lolnub
//
//  Created by Anonymous on 11/15/13.
//  Copyright (c) 2014 lolnub.com developers All rights reserved.
//

#import "NubMode.h"

static NSDictionary *infoFields = nil;

#define VISIBLE_SIZE_PADDING                    50.0
#define ITEMS_COUNT_FUDGE_FACTOR                4


@interface NubMode ()

- (void)x_setPreviewSize:(CGFloat)newPreviewSize;

@end


@implementation NubMode

- (NSString *)modeName {
    return @"nub";
}

- (BOOL)isAdminMode {
    return NO;
}

- (BOOL)isSingleton {
    return NO;
}

- (id)init {
    self = [super init];
    
    if (self) {
        if (!infoFields) {
            infoFields = @{
                           NubItemKindAttribute          : @"Kind",
                           NubItemDateCreatedAttribute   : @"Created",
                           NubItemDateModifiedAttribute  : @"Modified",
                           NubItemDateAddedAttribute     : @"Added",
                           NubItemDateOpenedAttribute    : @"Last Opened",
                           NubItemOpenCountAttribute     : @"Times Opened",
                           NubItemSizeAttribute          : @"Size",
                           NubItemLinkedItemsAttribute   : @"Links"
                           };
        }
        
    }
    
    return self;
}

- (void)awakeFromNib {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif

    [self performSelectorInBackground:@selector(x_updateHumanInfo) withObject:nil];
    
    [(NSView *)[self baseView] display];
    [[self moreView] display];
    
    [(NSScrollView *)self.itemView.superview setDocumentView:self.itemView];

}

- (void)afterAwakeFromNib {
    
    
    // init our Items
    self.itemSource = [[NubItemSource alloc] initWithDataSource:self.nub.bucketManager andAttributes:[NubItemSource defaultSessionAttributes]];
    
    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
    
    [noteCenter addObserver: self.itemView
                   selector: @selector(reloadData)
                       name: NubItemSourceDidUpdateNotification
                     object: self.itemSource];
    
    [noteCenter addObserver: self
                   selector: @selector(x_updateHumanInfo)
                       name: NubItemViewSelectionDidChangeNotification
                     object: self.itemView];
    
    
    
    // update our query string
    NSString *query = self.itemSource.attributes[NubItemQueryAttribute];
    if (!query) {
        query = DEFAULT_QUERY_STRING;
    }
    self.nubspace = query;
    
    // setup the itemView
    self.itemView.delegate          = self;
    self.itemView.dataSource        = self.itemSource;
    self.itemView.backgroundColor   = [NSColor clearColor];
    
    // hack up the limit binding...
    [self.sessionLimit selectItemWithTag:0];
    [self reloadData];
    
    [super afterAwakeFromNib];
}

- (void)fullyAwake {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performNubspace:) name:NSControlTextDidChangeNotification object:self.nub.nubspaceView];

    // call super for fully redisplay
    [super fullyAwake];
}

- (void)sleepToBackground {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.nub.nubspaceView];

    [super sleepToBackground];
}

- (void)reloadData {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    if ([NSThread isMainThread]) {
        [self performSelectorInBackground:@selector(reloadData) withObject:nil];
        return;
    }
    
    [self.itemSource reloadData];
    [self.itemView reloadData];
    
    [self x_updateHumanInfo];
}

- (void)dealloc {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
    
    [noteCenter removeObserver:self];
}

- (NSArray *)selectedItems {
    return self.itemView.selectedItems;
}


#pragma mark NSResponder

- (NSMenu *)menuForEvent:(NSEvent *)event {
    return self.itemContextMenu;
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)local {
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pasteBoard = [sender draggingPasteboard];
    
    return [[pasteBoard types] containsObject:NSFilenamesPboardType] ? NSDragOperationCopy : NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pasteBoard = [sender draggingPasteboard];
    
    // cancel the drag unless we're getting files
    if (![[pasteBoard types] containsObject:NSFilenamesPboardType]) {
        return NO;
    }
    
    // grab the files from the pasteboard and forward them to our delegate (the Nub)
    [self.delegate importPaths:[pasteBoard propertyListForType:NSFilenamesPboardType]];
    
    return YES;
}

- (IBAction)performNubspace:(id)sender {
    self.nubspace = self.nub.nubspaceView.stringValue;
    
    // manually connect the query to superhash
    [self.itemSource.attributes setValue:self.nubspace                          forKey:NubItemQueryAttribute];
    [self.itemSource.attributes setValue:@(self.sessionArrangeBy.selectedTag)   forKey:NubItemArrangeByAttribute];
    [self.itemSource.attributes setValue:@(self.sessionOrderBy.selectedTag)     forKey:NubItemOrderByAttribute];
    [self.itemSource.attributes setValue:@(self.sessionLimit.selectedTag)       forKey:NubItemLimitAttribute];
    
    [self reloadData];
}

#pragma mark Actions
- (IBAction)createItem:(id)sender {
    NSString *keycode = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *keyPath = [self.nub.bucketPath stringByAppendingPathComponent:keycode];
    
    [keycode writeToFile:keyPath atomically:YES encoding:NSUnicodeStringEncoding error:NULL];
    
    [self.nub importPaths:@[keyPath]];
}

- (IBAction)openSelectedItems:(id)sender {
    [super openInternal:sender];
}

- (IBAction)openInternal:(id)sender {
    [self.delegate setMode:BotBucketMode actionCallback:^(BotMode *botMode) {
        [botMode addBotItems:self.itemView.selectedItems];
    }];
}

- (void)openExternalItems:(NSArray *)items {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    
    for (NubItem *item in self.itemView.selectedItems) {
        [workspace openFile:item.path];
    }
}


#pragma mark Options

- (CGFloat)previewSize {
    //#ifdef DEBUG_CAVEMAN
    //    DebugLog();
    //#endif
    
    CGFloat visibleSize     = self.itemView.bounds.size.width;
    CGFloat savedSize       = [super previewSize];
    
    if (savedSize < visibleSize) {
        return savedSize;
    }
    
    return visibleSize - VISIBLE_SIZE_PADDING;
}

- (NSUInteger)itemRating {
    if (self.itemView.selectedItems.count == 1) {
        return [[[[self.itemView selectedItems] lastObject] get:NubItemRatingAttribute] integerValue];
    }
    
    return NubItemRatingValueNeutral;
}

- (void)setItemRating:(id)sender {
    if (!self.itemView.selectedItems.count) {
        return;
    }
    
    NSNumber *newRating = nil;
    
    // handle a hardcoded NSPopupMenu or a Regular Menu
    if ([sender respondsToSelector:@selector(selectedItem)]) {
        newRating = @([[sender selectedItem] tag]);
    }
    else {
        newRating = @([sender tag]);
    }
    
    @synchronized(self.itemView.selectedItems) {
        NSArray *items = self.itemView.selectedItems;
        
        [items enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NubItem *item, NSUInteger index, BOOL *stop) {
            // @todo pretty kludgy... but update the attrs of the item
            item.rating = newRating;
        }];
        
        // if the item was loved, add to yay items.
        // was this a love?
//        if ([newRating integerValue] == NubItemRatingValueLove) {
//            @throw @"[self.nub addBotItems:items]";
//        }
    }
    
    [self x_updateHumanInfo];
    
    // then push it to the nub
    [self.delegate save:self];
    [self performNubspace:self];
}

- (IBAction)setDesktopPicture:(id)sender {
    if (!self.selectedItems || self.selectedItems.count < 1) {
        return;
    }
    
    NubItem *item = (self.selectedItems)[0];
    
    if (item) {
        [[NSWorkspace sharedWorkspace] setDesktopImageURL:[NSURL fileURLWithPath:item.path] forScreen:[NSScreen mainScreen] options:nil error:NULL];
    }
}



#pragma mark Private

- (void)x_updateHumanInfo {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    // update our about/help dialog
    NSArray *selectedItems = [self selectedItems];
    
    if (selectedItems.count != 1) {
        self.itemName.stringValue   = DEFAULT_EMPTY_STRING;
        self.itemCode.stringValue  = DEFAULT_EMPTY_STRING;
        
        return;
    }
    
    NubItem *selectedItem = selectedItems.lastObject;
    
    [self.itemName setEnabled:NO];
    [self.itemName setStringValue:selectedItem.nubspace];
    
    [self.itemCode setEnabled:YES];
    [self.itemCode setStringValue:selectedItem.codes];
    
    
    // item counts
    NSString *statsString = nil;
    
    NSUInteger itemsCount   = [self.itemSource itemsCount];
    NSUInteger totalCount   = [self.itemSource totalItemsCount];
    
    NSUInteger delta        = totalCount - itemsCount;
    
    if (itemsCount == 1) {
        statsString = @"1 item";
    }
    else {
        if (delta == 0) {
            statsString = [NSString stringWithFormat:@"%@ total", [NSNumberFormatter localizedStringFromNumber:@(itemsCount) numberStyle:NSNumberFormatterDecimalStyle]];
        }
        else {
            statsString = [NSString stringWithFormat:@"%@ items", [NSNumberFormatter localizedStringFromNumber:@(itemsCount) numberStyle:NSNumberFormatterDecimalStyle]];
        }
        
        double deltaPercent = (double)itemsCount / (double)totalCount;
        
        if ((delta > ITEMS_COUNT_FUDGE_FACTOR) && deltaPercent > 0.10) {
            statsString = [statsString stringByAppendingFormat:@" (%@)",
                           [NSNumberFormatter localizedStringFromNumber:@(deltaPercent) numberStyle:NSNumberFormatterPercentStyle]
                           ];
        }
    }
    
    // update item counts in the banner
    self.feedback.stringValue = statsString;
}

- (void)x_setPreviewSize:(CGFloat)newPreviewSize {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    [super x_setPreviewSize:(CGFloat)newPreviewSize];
    
    [self.itemView reloadLayout];
}

- (NSMutableArray *)x_defaultSessions {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    NSMutableArray *defaultSessions = [NSMutableArray array];
    
    if (!defaultSessions) {
        NSMutableDictionary *every = [NubItemSource defaultSessionAttributes];
        every[NubItemNameAttribute]        = @"#private";
        every[NubItemImagesAttribute]      = @(1);
        every[NubItemMoviesAttribute]      = @(1);
        every[NubItemOthersAttribute]      = @(1);
        every[NubItemDefaultAttribute]     = @(YES);
        
        [defaultSessions addObject:every];
        
//        NSMutableDictionary *images = [NubItemSource defaultSessionAttributes];
//        images[NubItemNameAttribute]        = @"#private #image";
//        images[NubItemImagesAttribute]      = @(0);
//        images[NubItemMoviesAttribute]      = @(0);
//        images[NubItemOthersAttribute]      = @(0);
//        images[NubItemDefaultAttribute]     = @(YES);
//        [defaultSessions addObject:images];
//        
//        NSMutableDictionary *movies = [NubItemSource defaultSessionAttributes];
//        movies[NubItemNameAttribute]        = @"#private #movies";
//        movies[NubItemImagesAttribute]      = @(0);
//        movies[NubItemMoviesAttribute]      = @(1);
//        movies[NubItemOthersAttribute]      = @(0);
//        movies[NubItemDefaultAttribute]     = @(YES);
//        [defaultSessions addObject:movies];
//        
//        NSMutableDictionary *others = [NubItemSource defaultSessionAttributes];
//        others[NubItemNameAttribute]        = @"#private #others";
//        others[NubItemImagesAttribute]      = @(0);
//        others[NubItemMoviesAttribute]      = @(0);
//        others[NubItemOthersAttribute]      = @(1);
//        others[NubItemDefaultAttribute]     = @(YES);
//        [defaultSessions addObject:others];
//        
//        NSMutableDictionary *newest = [NubItemSource defaultSessionAttributes];
//        newest[NubItemNameAttribute]        = @"#private #newest";
//        newest[NubItemImagesAttribute]      = @(1);
//        newest[NubItemMoviesAttribute]      = @(1);
//        newest[NubItemOthersAttribute]      = @(1);
//        newest[NubItemArrangeByAttribute]   = @(NubItemArrangeByDateAdded);
//        newest[NubItemOrderByAttribute]     = @(NubItemOrderByDescending);
//        newest[NubItemLimitAttribute]       = @(100);
//        newest[NubItemDefaultAttribute]     = @(YES);
//        [defaultSessions addObject:newest];
//        
//        NSMutableDictionary *favorites = [NubItemSource defaultSessionAttributes];
//        favorites[NubItemNameAttribute]        = @"#private #best";
//        favorites[NubItemImagesAttribute]      = @(1);
//        favorites[NubItemMoviesAttribute]      = @(1);
//        favorites[NubItemOthersAttribute]      = @(1);
//        favorites[NubItemArrangeByAttribute]   = @(NubItemArrangeByOpenCount);
//        favorites[NubItemOrderByAttribute]     = @(NubItemOrderByDescending);
//        favorites[NubItemLimitAttribute]       = @(100);
//        favorites[NubItemDefaultAttribute]     = @(YES);
//        [defaultSessions addObject:favorites];
//        
        [self.delegate save:self];
    }
    
    return defaultSessions;
}


@end
