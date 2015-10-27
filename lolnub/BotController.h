//
//  BotController.h
//  lolnub
//
//  Created by Anonymous on 8/19/10.
//  Copyright 2014 the lolnub project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Bot.h"

@interface BotController : NSObject {}

@property (strong) NSOperationQueue				*botQueue;

@property (strong) NSMutableArray				*bots;

@property (strong) IBOutlet NSPanel				*botPanel;
@property (strong) IBOutlet NSTextField			*botStatus;
@property (strong) IBOutlet NSProgressIndicator	*botProgress;
@property (strong) IBOutlet NSTableView			*botTable;
@property (strong) IBOutlet NSProgressIndicator *botIndicator;

#pragma mark Bots

- (void)addAndStartBot:(NSNotification *)notification;
- (void)removeBot:(NSNotification *)notification;

- (void)cancelBotsWithOwner:(id)owner transient:(BOOL)transient;
- (void)terminateAllBots;

- (void)updateBotStatus;

#pragma mark Interface

- (IBAction)showBotPanel:(id)sender;

@end
