//
//  BotMode.h
//  Happy
//
//  Created by Anonymous on 10/18/12.
//  Copyright (c) 2012 lolnub.com. All rights reserved.
//

#import "WebKit/WebKit.h"

#import "ModeController.h"
#import "NubSpecialView.h"

@interface BotMode : ModeController


@property (strong) NubItem                        *specialItem;
@property (strong) IBOutlet NubSpecialView        *specialView;

@property (strong) IBOutlet NSTableView           *itemTable;

@property (strong) IBOutlet WebView               *webView;

@property (strong) IBOutlet NSMenu                *contextMenu;


//- (void)addBotItems:(NSArray *)items;
- (IBAction)beamBotItems:(id)sender;

//- (IBAction)removeBotItem:(id)sender;
//- (void)removeBotItems:(NSArray *)items;
//
//- (IBAction)showBotItems:(id)sender;
//- (IBAction)pushBotItems:(id)sender;
//
//- (void)shareBotItems:(NSArray *)items;

- (IBAction)openBlob:(id)sender;

@end
