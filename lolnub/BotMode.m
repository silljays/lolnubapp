//
//  BotMode.m
//  Happy
//
//  Created by Anonymous on 10/18/12.
//  Copyright (c) 2012 lolnub.com. All rights reserved.
//

#import "BotMode.h"

#define RELOAD_DATA_INTERVAL            1.0

@interface BotMode ()
@end


@implementation BotMode

@synthesize specialItem;
@synthesize specialView;

@synthesize contextMenu;


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

    // check + init our mode's main datastore
    if (!self.bucketStorage[BUCKET_BOT_ITEMS_KEY]) {
        self.bucketStorage[BUCKET_BOT_ITEMS_KEY] = [NSMutableArray arrayWithCapacity:0];
    }
    
    // dark out the special view + tell webview we want transparency (so our CSS will show through)
    [self.webView setDrawsBackground:NO];
    
    [((WebView *)self.webView).mainFrame loadRequest:
     [NSURLRequest requestWithURL: [NSURL URLWithString:[DEFAULT_URI stringByAppendingString:@"data"]]
                      cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval:9.0]];
    
    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
    
    [noteCenter addObserver: self
                   selector: @selector(reloadData)
                       name: BotDidBeamtoURINotification
                     object: nil];
    
    
    [self reloadData];
}

- (void)fullyAwake {
    [super fullyAwake];
    
    [self reloadData];
}

- (void)reloadData {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        
        return;
    }
    
    [self.itemTable reloadData];
    [self.webView reloadFromOrigin:self];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    // fallback to the default, search for a new
    NSString *itemKeyPath = nil;
    NSInteger selectedRow = self.itemTable.selectedRow;
    
    if (NSLocationInRange(selectedRow, NSMakeRange(0, [self.bucketStorage[BUCKET_BOT_ITEMS_KEY] count]))) {
        itemKeyPath = self.bucketStorage[BUCKET_BOT_ITEMS_KEY][selectedRow];
        
        if (itemKeyPath) {
            NubItem *nubItem = [self.delegate.bucketManager itemFromKeyPath:itemKeyPath];
            
            if (nubItem) {
                self.specialItem = nubItem;
                [self.specialView setImageFromItem:nubItem];
            }
            else {
                self.specialItem = nil;
                [self.specialView setImageFromImage:[NSImage imageNamed:@"icon-app"]];
            }
        }
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.bucketStorage[BUCKET_BOT_ITEMS_KEY] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // fallback to the default, search for a new
    NSString *itemKeyPath = nil;
    
    if (NSLocationInRange(row, NSMakeRange(0, [self.bucketStorage[BUCKET_BOT_ITEMS_KEY] count]))) {
        itemKeyPath = self.bucketStorage[BUCKET_BOT_ITEMS_KEY][row];
        
        if (itemKeyPath) {
            return [self.delegate.bucketManager itemFromKeyPath:itemKeyPath].nubspace;
        }
    }
    
    // but pass the item here
    return DEFAULT_CAKE_STRING;
}

- (void)performNubspace:(id)sender {
    [self reloadData];
}


#pragma mark UX

//- (NSMenu *)menuForEvent:(NSEvent *)event {
//    return self.nub.itemContextMenu;
//}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)local {
    return NSDragOperationNone;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    //NSPasteboard *pasteBoard = [sender draggingPasteboard];
    
    return NO;
}


#pragma mark BotItems

- (NSArray *)botItems {
    return self.bucketStorage[BUCKET_BOT_ITEMS_KEY];
}

- (void)addBotItems:(NSArray *)items {
    if (!items || !items.count) {
        return;
    }
    
    // add the items
    for (NubItem *item in items) {
        if (![self.bucketStorage[BUCKET_BOT_ITEMS_KEY] containsObject:item]) {
            [self.bucketStorage[BUCKET_BOT_ITEMS_KEY] insertObject:item.uuid atIndex:0];
        }
    }
    
    [self reloadData];
}

- (void)beamBotItems:(id)sender {
    // uploads are background only
    if ([[NSThread currentThread] isMainThread]) {
        [self performSelectorInBackground:@selector(beamBotItems:) withObject:sender];
        
        return;
    }
    
    NSURL *uri = [NSURL URLWithString:DEFAULT_URI];

    for (NSString *itemKeyPath in [self.botItems objectsAtIndexes:self.itemTable.selectedRowIndexes]) {
        NubItem *item = [self.delegate.bucketManager itemFromKeyPath:itemKeyPath];

        Bot *upload = [[Bot alloc] init];
        
        [upload addItemToPOST:item];
        [upload addParamToPOST:item.codes withKeyName:@"code"];
        [upload beamToURI:uri];
    }
}

- (IBAction)openBlob:(id)sender {
    [super openInternalItems: @[self.botItems[self.itemTable.selectedRow]]];
}
@end
