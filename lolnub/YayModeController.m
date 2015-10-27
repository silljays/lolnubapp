//
//  YayModeController.m
//  lolnub
//
//  Created by Anonymous on 10/18/12.
//  Copyright (c) 2012 lolnub.com. All rights reserved.
//

#import "YayModeController.h"

#define DEFAULT_SIZE                    512.0
#define RELOAD_DATA_INTERVAL            1.0

static YayModeController *instance = nil;

@interface YayModeController ()
@end


@implementation YayModeController

@synthesize goldenView;
@synthesize goldenContextMenu;
@synthesize goldenIndex;
@synthesize goldenItem;

+ (id)sharedInstance {
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    
    return instance;
}

+ (BOOL)isSingleton {
    return YES;
}

- (BOOL)isAdminMode {
    return NO;
}

- (BOOL)wantsStatusView {
    return YES;
}

- (void)awakeFromNib {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    [super awakeFromNib];
    
    self.itemView.delegate          = self;
    self.itemView.dataSource        = self.x_goldenItems;
    
    self.goldenView.backgroundColor = [[NSColor darkGrayColor] blendedColorWithFraction:0.33 ofColor:[NSColor blackColor]];

    self.goldenIndex = [self x_goldenItems].count - 1;
    [self.goldenTable selectRowIndexes:[NSIndexSet indexSetWithIndex:self.goldenIndex] byExtendingSelection:NO];
    
    [self reloadData];
}

- (void)reloadData {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif

    // fallback to the default, search for a new
    NSString *goldenKeyPath = nil;

    if (NSLocationInRange(goldenIndex, NSMakeRange(0, self.x_goldenItems.count))) {
        goldenKeyPath = [self.x_goldenItems objectAtIndex:goldenIndex];
    }
    else {
        if (self.goldenItem) {
            goldenKeyPath = self.goldenItem.uuid;
        }
        else {
            // the default
            [self x_setDefaultGolden];
            goldenKeyPath = self.goldenItem.uuid;
        }
    }

    // but pass the item here
    self.goldenItem = [[self.delegate itemManager] itemFromKeyPath:goldenKeyPath];
    
    if (self.goldenItem) {
        [self.goldenView setImageFromItem:goldenItem];
        self.goldenNubcake.stringValue = self.goldenItem.nubspace;
    }

//    [self.goldenTable reloadData];
    //[self.itemView reloadData];

    [self performNubspace:self];

    [self.view display];
}

#pragma mark API

- (void)performNubspace:(id)sender {
    [[self nub] shareItems:[self x_goldenItems]];
}

#pragma mark API

- (void)addYayItems:(NSArray *)items {
    [[self delegate] addYayItems:items];

    [self reloadData];
}

- (IBAction)removeYayItem:(id)sender {
    NSString *goldenKeyPath = [self.bucketStorage[BUCKET_GOLDEN_ITEMS_KEY] lastObject];
    
    [self.bucketStorage[BUCKET_GOLDEN_ITEMS_KEY] removeObject:goldenKeyPath];
    
    [self reloadData];
}

- (IBAction)updateYayItems:(id)sender {
    switch ([sender selectedSegment]) {
        case 0:
            self.goldenIndex -= 1;
            break;
            
        default:
            self.goldenIndex += 1;
            break;
    }
    
    [self reloadData];
}


#pragma mark Cococa

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    self.goldenIndex = self.goldenTable.selectedRow;

    [self reloadData];
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
    return self.goldenContextMenu;
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
    
    // grab the files from the pasteboard and forward them to our delegate
    [self.delegate importPaths:[pasteBoard propertyListForType:NSFilenamesPboardType] completionBlock:^(NSArray *newItems) {
        [self.delegate addYayItems:newItems];
    }];
    
    [NSTimer scheduledTimerWithTimeInterval:RELOAD_DATA_INTERVAL target:self selector:@selector(reloadData) userInfo:nil repeats:NO];
    
    return YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.x_goldenItems.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    NSArray *selectedItems = [self selectedItems];
//    
//    if (selectedItems.count != 1) {
//        return @"";
//    }
    
//    NSString *rowKey = [[infoFields allKeys] sortedArrayUsingSelector:@selector(compare:)][row];
//    
//    id value = [(NubItem *)selectedItems.lastObject get:rowKey];
//    
//    if ([value isKindOfClass:[NSDate class]]) {
//        // todo: add a global date formatter
//        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//        
//        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
//        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
//        
//        return [@"" stringByAppendingFormat:@"%@ %@", infoFields[rowKey], [dateFormatter stringFromDate:value]];
//    }
    
    return @"n/a";
}

#pragma mark Private

- (NSArray *)x_goldenItems {
    return [self.bucketStorage[BUCKET_GOLDEN_ITEMS_KEY] sortedArrayUsingSelector:@selector(description)];
}

- (void)x_setDefaultGolden {
    [self.goldenView setImageFromImage:[NSImage imageNamed:APP_ICON_FILENAME]];
    [self.goldenView display];
}

@end
