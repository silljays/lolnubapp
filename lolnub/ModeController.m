//
//  ModeController.m
//  lolnub
//
//  Created by Anonymous on 11/1/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#define ITEM_MODE_PREVIEW_SIZE_KEY      @"Nub.mode.item.preview.key"

#import "ModeController.h"

@implementation ModeController

@synthesize delegate;
@synthesize dataSource;
@synthesize nubspace;
@synthesize selectedItems;
@synthesize actionCallback;


+ (id)sharedInstance {
    return nil;
}

- (Nub *)nub {
    return self.delegate;
}

+ (NSInteger)modeIndex {
    @throw @"subclasses need to implement";
}

- (NSString *)modeName {
    @throw @"subclasses need to implement";
}

- (NSString *)nibName {
    return [NSStringFromClass(self.class) stringByReplacingOccurrencesOfString:@"Controller" withString:@""];
}

- (NSMutableDictionary *)bucketStorage {
    return self.delegate.bucketStorage;
}

- (BOOL)isReadable {
    return (self.delegate).isReadable;
}

- (NSWindow *)window {
    return self.view.window;
}

- (NSView *)baseView {
    return _baseView ? _baseView : self.view;
}

- (void)awakeFromNib {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
}

- (void)afterAwakeFromNib {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    if (![self.baseView isHidden]) {
        [[self.baseView superview] display];
    }
}

- (void)awakeFromBackground {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    self.view.hidden = NO;
    self.moreView.hidden = NO;
}

- (void)fullyAwake {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    // exec the callback, then set it to nil so the next
    // trip through the modeButtons we will re-calc the callback
    if (self.actionCallback) {
        self.actionCallback(self);
        
        self.actionCallback = nil;
    }

    self.view.hidden = NO;
    self.moreView.hidden = NO;
}

- (void)sleepToBackground {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    self.view.hidden = YES;
    self.moreView.hidden = YES;
}

- (void)fullyClose {
    
}

- (IBAction)performNubspace:(id)sender {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    [self reloadData];
}

- (IBAction)toggleMeta:(id)sender {
    NSBeep();
}

- (IBAction)reloadData:(id)sender {
    [self reloadData];
}

- (void)reloadData {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif

}

+ (BOOL)isSingleton {
    return NO;
}

- (BOOL)isAdminMode {
    @throw @"subclasses need to implement";
}

- (BOOL)isSwitchable {
    return YES;
}

- (CGFloat)previewSize {
//#ifdef DEBUG_CAVEMAN
//    DebugLog();
//#endif
    
    CGFloat storedPixelSize = [self.bucketStorage[ITEM_MODE_PREVIEW_SIZE_KEY] floatValue];
    
    
    if (storedPixelSize < MIN_PIXEL_SIZE) {
        storedPixelSize = DEFAULT_PIXEL_SIZE;
    }
    
    return storedPixelSize;
}

- (IBAction)setPreviewSize:(id)sender {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    CGFloat newPreviewSize = ceilf([sender floatValue]);
    
    if (newPreviewSize < MIN_PIXEL_SIZE) {
        newPreviewSize = MIN_PIXEL_SIZE;
    }
    
    [self x_setPreviewSize:newPreviewSize];
}


#pragma mark Actions

- (void)openSelectedItems:(id)sender {
    [self openInternal:sender];
}

- (IBAction)openWindow:(id)sender {
    [self openInternalItems:self.selectedItems];
}

- (IBAction)openInternal:(id)sender {
    [self openInternalItems:self.selectedItems];
}

- (IBAction)openExternal:(id)sender {
    [self openExternalItems:self.selectedItems];
}

- (void)openInternalItems:(NSArray *)items {
//    for (NubItem *item in items) {
//        NubMedia *mediaController = [[NubMedia alloc] initWithWindowNibName:@"Media"];
//        
//        [mediaController.window display];
//        [mediaController openItem:item];
//        
//        [self.nub.mediaControllers addObject:mediaController];
//    }
    [self.nub setMode:BotBucketMode actionCallback:^(BotMode *botMode) {
        [botMode addBotItems:items];
    }];
}

- (void)openExternalItems:(NSArray *)items {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    
    for (NubItem *item in items) {
        [workspace openFile:item.path];
    }
}


#pragma mark Special

- (void)addBotItems:(NSArray *)items {
    if (!items || !items.count) {
        return;
    }
    
    for (NubItem *item in items) {
        [self.bucketStorage[BUCKET_ITEM_MODE_SESSIONS_KEY] addObject:item.uuid];
    }
    
    [self.nub save:self];
    [self reloadData];
}

- (void)removeBotItems:(NSArray *)items {
    if (!items || !items.count) {
        return;
    }
    
    for (NubItem *item in items) {
        [self.bucketStorage[BUCKET_ITEM_MODE_SESSIONS_KEY] removeObject:item.uuid];
    }
    
    [self.nub save:self];
    [self reloadData];
}

- (IBAction)pushBotItems:(id)sender {
    [self shareBotItems:self.botItems];
    [self reloadData];
}

- (void)shareBotItems:(NSArray *)items {
    //    NSURL *uri = [NSURL URLWithString:DEFAULT_URI];
    //
    //    for (NSString *itemPath in items) {
    //        Bot *upload = [[Bot alloc] init];
    //
    //        NubItem *item = [self.bucketManager itemFromKeyPath:itemPath];
    //
    //        [upload addItemToPOST:item];
    //        [upload addParamToPOST:item.codes withKeyName:@"item[data]"];
    //        [upload beamToURI:uri];
    //    }
}

- (NSArray *)botItems {
    NSArray *uuids = self.bucketStorage[BUCKET_ITEM_MODE_SESSIONS_KEY];
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:uuids.count];
    
    for (NSString *itemKeyPath in uuids) {
        //NSLog(@"keyPath: %@", itemKeyPath);
        
        NubItem *item = [self.nub.bucketManager itemFromKeyPath:itemKeyPath];
        
        if (item) {
            [items addObject:[self.nub.bucketManager itemFromKeyPath:itemKeyPath]];
        }
    }
    
    return items;
}

- (IBAction)deleteSelectedItems:(id)sender {
    [self deleteItems:self.selectedItems];
}

- (void)deleteItems:(NSArray *)items {
    [self.nub.bucketManager removeItems:items];
    
    [self.nub save:self];
}


#pragma mark Private

- (void)x_setPreviewSize:(CGFloat)newPreviewSize {
#ifdef DEBUG_CAVEMAN
    //DebugLog();
#endif
    
    // store the new itemSize in the storage manager
    (self.bucketStorage)[ITEM_MODE_PREVIEW_SIZE_KEY] = [NSNumber numberWithFloat:newPreviewSize];        
}

@end
