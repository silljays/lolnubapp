//
//  Nub.m
//  lolnub
//
//  Created by lolnub.com developers on 10/13/13.
//  Copyright (c) 2014 lolnub.com developers All rights reserved.
//

#import "Nub.h"
#import "NubWindowController.h"

#define BUCKET_SAVE_SOON_INTERVAL               1
#define BUCKET_MODE_NOT_INIT_YET                -9000

#define BUCKET_OPTIONS_FILENAME                 @".nub.options.secure.name"

#define BUCKET_IMPORT_PATHS_UUID_KEY            @".nub.import.paths"
#define BUCKET_IMPORT_PATHS_PAYLOAD_KEY         @".nub.import.paths.payload"
#define BUCKET_IMPORT_PATHS_ITEMS_KEY           @".nub.import.paths.items"
#define BUCKET_IMPORT_PATHS_BLOCK_KEY           @".nub.import.paths.block"

#define KEY_POST_NAME                           @"postName"
#define KEY_POST_STRING                         @"postString"
#define KEY_POST_IMAGE                          @"postImage"
#define KEY_POST_IMAGE_FILE_NAME                @"postImageFileName"

#define BOUNDARY                                @"----NubAppsFormBoundaryByUploader"

NSString *const NubModeDidChangeNotification   = @"BucketModeDidChangeNotification";
NSString *const NubDidImportPathsNotification  = @"BucketDidImportPathsNotification";


@interface Nub ()

@property (strong) NSMutableArray *x_modeControllerCache;

- (NSString *)x_bucketStoragePath;
- (void)x_initBucketStorage;

@end


@implementation Nub

@synthesize moreView;
@synthesize contentView;
@synthesize modeView;
@synthesize nubspaceView;

@synthesize documentPath;
@synthesize bucketPath;
@synthesize bucketManager;
@synthesize bucketStorage;

@synthesize mode;
@synthesize modeController;
@synthesize mediaControllers;


#pragma mark NSDocument

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName {
    return YES;
}

+ (void)registerModeController:(ModeController *)modeController {
    // todo: dynamically load the modes
}

- (id)initWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
    self = [super init];
    
    if (self) {
        mode                            = BUCKET_MODE_NOT_INIT_YET;
        _isReadable                     = NO;
        
        self.documentPath               = [url path];
        self.mediaControllers           = [NSMutableArray array];
        self.x_modeControllerCache      = [NSMutableArray array];
    }
    
    return self;
}

- (void)makeWindowControllers {
    [self addWindowController:[[NubWindowController alloc] initWithWindowNibName:@"Nub" owner:self]];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController {
    // override close behaviour
    [windowController setShouldCloseDocument:YES];
    
    // determine the mode basically on wether initWithContentsOfURL and a path was set
    self.mode = documentPath ? DecryptBucketMode : EncryptBucketMode;
}

- (NubBrandWindow *)window {
    NubBrandWindow *window = nil;
    
    @try {
        window = (NubBrandWindow *)[(self.windowControllers)[0] window];
        
        [window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
    }
    @catch (NSException *exception) { /* in case window is called before the nib is loaded we noop this call */ }
    
    return window;
}

- (NSArray *)modeControllers {
    return self.x_modeControllerCache;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    return YES;
}


#pragma mark Nub

- (void)save:(id)sender {
    [bucketStorage writeToFile:[self x_bucketStoragePath] atomically:YES];
    
    [bucketManager saveItems];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.x_modeControllerCache.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < 0 || row > self.x_modeControllerCache.count) {
        return [NSImage imageNamed:@"patches-logo_512px"];
    }
    
    NSString *tag = [[NSStringFromClass([self.x_modeControllerCache[row] class]) substringWithRange:NSMakeRange(0, 3)] lowercaseString];
    
    if([tag isEqualToString:@"nub"]) {
        return [NSImage imageNamed:@"patches-logo_512px"];
    }
    else if([tag isEqualToString:@"bot"]) {
        return [NSImage imageNamed:@"castle-logo_512px"];
    }
    else if([tag isEqualToString:@"web"]) {
        return [NSImage imageNamed:@"nubcake-logo_512px"];
    }

    return [NSImage imageNamed:@"patches-logo_512px"];

//    NSView *rowView     = [[self.x_modeControllerCache objectAtIndex:row] view];
//    NSImage *image      = [[NSImage alloc] initWithSize:rowView.frame.size];
//    BOOL rowViewHidden  = rowView.hidden;
//    
//    rowView.hidden = NO;
//    image = [[NSImage alloc] initWithData:[rowView dataWithPDFInsideRect:[rowView frame]]];
//    rowView.hidden = rowViewHidden;
//
//    return image;
}


#pragma mark Modes

- (void)setBucketPath:(NSString *)mountedBucketPath {
    bucketPath = mountedBucketPath;
    
    if (bucketPath) {
        // grab the items
        self.bucketManager = [[NubBucketManager alloc] initWithPath:self.bucketPath];
        self.isReadable  = self.bucketManager ? YES : NO;
        
        // init the Nub-global storage dictionary
        [self x_initBucketStorage];
        
        // re-init the saved Nub.window.frame
        NSString *windowFrame = bucketStorage[BUCKET_WINDOW_FRAME_KEY];
        if (windowFrame) {
            [self.window setFrame:NSRectFromString(windowFrame) display:YES animate:YES];
        }
        
        // re-init the saved Nub.mode
        @try {
            self.mode = [bucketStorage[BUCKET_CURRENT_MODE_KEY] integerValue];
        }
        @catch (NSException *exception) {
            self.mode = DEFAULT_BUCKET_MODE;
        }
    }
    else {
        self.bucketManager  = nil;
        self.isReadable     = NO;
    }
}

- (NSString *)modeString {
    switch (self.mode) {
        case PasscodeBucketMode:
            return @"passcode";
            break;
            
        case NubBucketMode:
            return @"nub";
            break;
            
        case BotBucketMode:
            return @"bot";
            break;
            
        case WebBucketMode:
            return @"web";
            break;
            
    }
    
    return nil;
}

- (void)selectHudMode:(id)sender {
    [self setModeIndex:[self.modeTable selectedRow]];
}

- (void)selectMode:(id)sender {
    // don't select modes from non-switchable controllers
    if (modeController && !modeController.isSwitchable) {
        return;
    }
    
    NSInteger buttonMode = 0;
    
    NSString *tag = [sender identifier];
    
    if([tag isEqualToString:@"passcode"]) {
        buttonMode = PasscodeBucketMode;
    }
    else if([tag isEqualToString:@"nub"]) {
        buttonMode = NubBucketMode;
    }
    else if([tag isEqualToString:@"web"]) {
        buttonMode = WebBucketMode;
    }
    else if([tag isEqualToString:@"bot"]) {
        buttonMode = BotBucketMode;
    }
    
    self.mode = buttonMode;
}

- (void)setModeIndex:(NSInteger)modeIndex {
    if (modeIndex < 0 || modeIndex > self.x_modeControllerCache.count) {
        return;
    }
    
    id newModeController = [self.x_modeControllerCache objectAtIndex:modeIndex];
    if ([self.modeController isEqualTo:newModeController]) {
        return;
    }
    // Clear or sleep any current modeController
    if (modeController) {
        [modeController sleepToBackground];
    }
    self.modeController = newModeController;
    modeController.delegate = self;
    
    // Position the views
    NSRect contentRect = contentView.frame;
    
    if (modeController.isAdminMode) {
        modeController.view.frame = NSMakeRect(0.0, 0.0, contentRect.size.width, contentRect.size.height);
        
        [self.contentView addSubview:modeController.view positioned:NSWindowAbove relativeTo:moreView];
    }
    else {
        modeController.view.frame = modeView.bounds;
        
        [self.modeView addSubview:modeController.view];
    }
    
    // "cleanup" events
    [modeController afterAwakeFromNib];
    [modeController fullyAwake];
    
    [self x_syncInterface];
}

- (void)setMode:(BucketMode)newBucketMode {
    [self setMode:newBucketMode actionCallback:nil];
}

- (void)setMode:(BucketMode)newBucketMode actionCallback:(void (^)(id object))completeBlock {
    mode = newBucketMode;
    
    // Clear or sleep any current modeController
    if (modeController) {
        [modeController sleepToBackground];
    }
    
    // Get new mode class
    Class activeModeControllerClass = nil;
    
    switch (self.mode) {
        case SecureBucketMode:
            activeModeControllerClass = [ExitMode class];
            break;
            
        case EncryptBucketMode:
            activeModeControllerClass = [EncryptMode class];
            break;
            
        case DecryptBucketMode:
            activeModeControllerClass = [DecryptMode class];
            break;
            
        case PasscodeBucketMode:
            activeModeControllerClass = [OptionsMode class];
            break;
            
        case NubBucketMode:
            activeModeControllerClass = [NubMode class];
            break;
            
        case WebBucketMode:
            activeModeControllerClass = [WebMode class];
            break;
            
        case BotBucketMode:
            activeModeControllerClass = [BotMode class];
            break;
            
        default:
            NSLog(@"unknown bucketMode so we are switching to the default instead.");
            activeModeControllerClass = [NubMode class];
            break;
    }
    
    if ([activeModeControllerClass isSingleton]) {
        self.modeController = [activeModeControllerClass sharedInstance];
    }
    else {
        self.modeController = [[activeModeControllerClass alloc] init];
    }
    
    // setup ourselves as delegate so there is always a connection to the nub
    modeController.delegate = self;
    
    if (!modeController.isAdminMode) {
        [self.x_modeControllerCache addObject:modeController];
    }
    
    // 3a) assign the modeController any callback or nil to reset the callback
    modeController.actionCallback = completeBlock;
    
    // 3b) POSITION THE VIEWS
    NSRect contentRect = contentView.frame;
    
    if (modeController.isAdminMode) {
        modeController.view.frame = NSMakeRect(0.0, 0.0, contentRect.size.width, contentRect.size.height);
        
        [self.contentView addSubview:modeController.view positioned:NSWindowBelow relativeTo:moreView];
    }
    else {
        modeController.view.frame = modeView.bounds;
        
        [self.modeView addSubview:modeController.view];
    }
    [modeController afterAwakeFromNib];
    
    // Call `actionCallback` block.
    modeController.actionCallback = completeBlock;
    
    // Last call..
    [modeController fullyAwake];
    
    [self performSelectorInBackground:@selector(x_syncInterface) withObject:nil];
}


#pragma mark Import/Export

- (IBAction)importFiles:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:YES];
    [panel setAllowsMultipleSelection:YES];
    [panel setPrompt:@"Import..."];
    
    if (![panel runModal] == NSFileHandlingPanelOKButton) {
        return;
    }
    
    // convert the NSURLs into path NSStrings
    NSMutableArray *paths = [NSMutableArray array];
    
    for (NSURL *fileURL in [panel URLs]) {
        [paths addObject:[fileURL relativePath]];
    }
    
    [self performSelectorInBackground:@selector(importPaths:) withObject:paths];
}

- (NSString *)importPaths:(NSArray *)paths {
    return [self importPaths:paths completionBlock:^(NSArray *newItems) {}];
}

- (NSString *)importPaths:(NSArray *)paths completionBlock:(void (^)(NSArray *newItems))completeBlock {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    [self.bucketManager importPaths:paths];
    
    return nil;
}

- (IBAction)exportItems:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel setPrompt:@"Export Here"];
    
    if (![panel runModal] == NSFileHandlingPanelOKButton) {
        return;
    }
    
    NSString *exportPath = [[panel URL] path];
    
    // verify that export path is not a path of the current Nub
    if ([exportPath hasPrefix:bucketPath]) {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"You seem to have selected a folder already on this Nub to export files."];
        [alert setInformativeText:@"Select another disk, folder, or location and try again."];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert runModal];
        
        return;
    }
    
    unsigned long long freeBytesOfExportDisk = 0;
    unsigned long long usedBytesOfBucket = 0;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    freeBytesOfExportDisk   = [fileManager freeByteCountOfFileSystemContainingPath:exportPath];
    usedBytesOfBucket         = [fileManager usedByteCountOfFileSystemContainingPath:bucketPath];
    
    // verify the new location has enough free disk space
    if (usedBytesOfBucket > freeBytesOfExportDisk) {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"The disk, folder, or location you selected for export does not have enough free space."];
        [alert setInformativeText:[NSString stringWithFormat:@"Delete or move %@ of files from the chosen location and try again.",
                                   [NSString stringFromByteCount:(usedBytesOfBucket - freeBytesOfExportDisk)]]];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert runModal];
        
        return;
    }
    
    [self.bucketManager performSelectorInBackground:@selector(exportStoredItemsToPath:) withObject:exportPath];
}

- (IBAction)closeMode:(id)sender {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    // check there is at least one mode still open.
    if (self.x_modeControllerCache.count > 1) {
        [modeController sleepToBackground];
        [self.x_modeControllerCache removeObject:modeController];
        [modeController fullyClose];
        
        [self.modeTable deselectAll:sender];
        [self.modeTable reloadData];
        
        [self selectHudMode:sender];
    }
}


- (IBAction)close:(id)sender {
    self.mode = SecureBucketMode;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark Private

- (void)x_syncInterface {
    if ([NSThread isMainThread]) {
        [self performSelectorInBackground:@selector(x_syncInterface) withObject:nil];
        return;
    }
    
    // Arrange secondary views, according to isAdminMode
    self.metaView.hidden = self.moreView.hidden = modeController.isAdminMode;
    
    @try {
        [self.modeTable reloadData];
        [self.modeTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.x_modeControllerCache indexOfObject:modeController]] byExtendingSelection:NO];
    }
    @catch (NSException *exception) {
    }
    
    // Arrange secondary views, according to isAdminMode
    self.moreView.hidden = self.modeTable.hidden = modeController.isAdminMode;
    
    // Finish Up
    [modeController fullyAwake];
    [modeController.view setNeedsDisplay:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NubModeDidChangeNotification object:self.window];
    
    // save the last mode to restore to when we open again
    if (!modeController.isAdminMode) {
        self.bucketStorage[BUCKET_CURRENT_MODE_KEY] = @(mode);
    }
    // Finish Up
    [modeController fullyAwake];
    [modeController.view setNeedsDisplay:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NubModeDidChangeNotification object:self.window];
    
    // save the last mode to restore to when we open again
    if (!modeController.isAdminMode) {
        self.bucketStorage[BUCKET_CURRENT_MODE_KEY] = @(mode);
    }
}

- (NSString *)x_bucketStoragePath {
    return [self.bucketPath stringByAppendingPathComponent:BUCKET_OPTIONS_FILENAME];
}

- (void)x_initBucketStorage {
    BOOL newBucketStorage = NO;
    
    // open and/or create the bucketStorage hash
    NSString *bucketStoragePath = [self x_bucketStoragePath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:bucketStoragePath]) {
        self.bucketStorage = [NSMutableDictionary dictionaryWithContentsOfFile:bucketStoragePath];
    }
    else {
        newBucketStorage    = YES;
        self.bucketStorage  = [NSMutableDictionary dictionary];
    }
    
    // CHECK/INIT DEFAULT KEYS
    if (!bucketStorage[BUCKET_WINDOW_FRAME_KEY]) {
        bucketStorage[BUCKET_WINDOW_FRAME_KEY] = NSStringFromRect(self.window.frame);
    }
    if (!bucketStorage[BUCKET_ITEM_MODE_SESSIONS_KEY]) {
        bucketStorage[BUCKET_ITEM_MODE_SESSIONS_KEY] = [NSMutableArray array];
    }
    if (!bucketStorage[BUCKET_CURRENT_MODE_KEY]) {
        bucketStorage[BUCKET_CURRENT_MODE_KEY] = @(DEFAULT_BUCKET_MODE);
    }
    
    if (newBucketStorage) {
        // first time write to disk
        [self.bucketStorage writeToFile:bucketStoragePath atomically:YES];
    }
}

@end
