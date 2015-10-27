//
//  ModeController.h
//  lolnub
//
//  Generic "Mode" controller for the UX.
//
//  Created by Anonymous on 11/1/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NubBucketManager.h"
#import "NubItem.h"

@class Nub;

@interface ModeController : NSViewController

@property (weak)                Nub                     *delegate;
@property (nonatomic, weak)     id                      dataSource;

@property (strong)              NSString                *nubspace;

@property (nonatomic, weak)     IBOutlet id             baseView;
@property (strong)              IBOutlet NSView         *moreView;

@property (strong)              NSMutableArray          *selectedItems;

@property (nonatomic, copy)     void                    (^actionCallback)(id object);


- (Nub *)nub;

+ (NSInteger)modeIndex;
- (NSString *)modeName;

// the global storage hash
- (NSMutableDictionary *)bucketStorage;

// is the Nub open/unencrypted?
- (BOOL)isReadable;
// subclasses implement to decide for singleton instances
+ (BOOL)isSingleton;
+ (id)sharedInstance;

// subclasses implement for admin or hidden UX modes (default: NO)
- (BOOL)isAdminMode;

// subclasses decide if the mode is switchable by UX controls or programatic only (default: YES)
- (BOOL)isSwitchable;

// hackish way to reposition aux views etc after our view/baseView is awake
- (void)awakeFromNib;
- (void)afterAwakeFromNib;
- (void)sleepToBackground;
- (void)awakeFromBackground;
- (void)fullyAwake;
- (void)fullyClose;

// generic message to reload the mode data
- (IBAction)reloadData:(id)sender;
- (void)reloadData;

// return the primary window of the mode
- (NSWindow *)window;

// update based on UX nubspace events
- (IBAction)performNubspace:(id)sender;

// show the #lolnub/meta panel
- (IBAction)toggleMeta:(id)sender;

// generic size slider
- (CGFloat)previewSize;
- (IBAction)setPreviewSize:(id)sender;
- (void)x_setPreviewSize:(CGFloat)newPreviewSize;

// action methods
- (IBAction)openInternal:(id)sender;
- (IBAction)openWindow:(id)sender;
- (IBAction)openExternal:(id)sender;


#pragma mark Items

// open items with the desktop/workspace
- (void)openExternalItems:(NSArray *)items;
// open the items with our built-in media viewer
- (void)openInternalItems:(NSArray *)items;

// remove items from the storage
- (IBAction)deleteSelectedItems:(id)sender;
- (void)deleteItems:(NSArray *)items;


#pragma mark Bot

- (void)addBotItems:(NSArray *)items;
- (void)removeBotItems:(NSArray *)items;
- (IBAction)pushBotItems:(id)sender;
- (void)shareBotItems:(NSArray *)items;
- (NSArray *)botItems;


@end
