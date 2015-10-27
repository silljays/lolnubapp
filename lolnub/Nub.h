//
//  Nub.h
//  lolnub
//
//  Created by lolnub.com developers on 10/13/13.
//  Copyright (c) 2014 lolnub.com developers All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "lolnub-Bridging-Header.h"

#import "Bot.h"
#import "NubBucket.h"
#import "NubBucketManager.h"

#import "NubBrandWindow.h"
#import "NubWindowController.h"
#import "NubBrandView.h"
#import "NubSpaceView.h"

#import "ExitMode.h"
#import "EncryptMode.h"
#import "DecryptMode.h"
#import "OptionsMode.h"

#import "NubMode.h"
#import "BotMode.h"
#import "WebMode.h"

extern NSString *const NubModeDidChangeNotification;
extern NSString *const NubDidImportPathsNotification;

enum {
    SecureBucketMode = 1,
    EncryptBucketMode,
    DecryptBucketMode,
    PasscodeBucketMode,
    
    NubBucketMode,
    WebBucketMode,
    BotBucketMode,
};
typedef NSInteger BucketMode;


@interface Nub : NSDocument <NSURLSessionDelegate, NSURLSessionDelegate, NSURLDownloadDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>

@property (assign, nonatomic)   BOOL                                isReadable;

@property (assign, nonatomic)   BucketMode                          mode;
@property (strong)              ModeController                      *modeController;
@property (strong)              NubBucketManager                    *bucketManager;

@property (strong, nonatomic)   NSString                            *documentPath;       // example.nub
@property (strong, nonatomic)   NSString                            *bucketPath;         // /tmp/example.nub
@property (strong)              NSMutableDictionary                 *bucketStorage;

@property (strong)              IBOutlet NSView                     *metaView;
@property (strong)              IBOutlet NSView                     *contentView;
@property (strong)              IBOutlet NSView                     *modeView;
@property (strong)              IBOutlet NSView                     *moreView;
@property (strong)              IBOutlet NSTextField                *nubspaceView;

@property (strong)              IBOutlet NSTableView                *modeTable;
@property (strong)              NSMutableArray                      *mediaControllers;


#pragma mark Generic

// our primary window
- (NubBrandWindow *)window;

// return the list of active modes
- (NSArray *)modeControllers;


#pragma mark Modes

// a (hackish) string to compare modes against
- (NSString *)modeString;

// select a mode (e.g. movies/images/cloud)
- (IBAction)selectMode:(id)sender;
- (IBAction)selectHudMode:(id)sender;

// set the mode normally, then execute the callback block
- (void)setModeIndex:(NSInteger)modeIndex;
- (void)setMode:(BucketMode)newBucketMode;
- (void)setMode:(BucketMode)newBucketMode actionCallback:(void (^)(id object))completeBlock;
- (IBAction)closeMode:(id)sender;


#pragma mark Blobs/Import/Export

// import files or folders into the Nub
- (IBAction)importFiles:(id)sender;

// return a UUID that observers can watch for
- (NSString *)importPaths:(NSArray *)paths;
- (NSString *)importPaths:(NSArray *)paths completionBlock:(void (^)(NSArray *newItems))completeBlock;

// copy all items from the Nub into a folder
- (IBAction)exportItems:(id)sender;


#pragma mark Close/Save

// close and secure the nub
- (void)close:(id)sender;

// save the nub
- (void)save:(id)sender;


@end

