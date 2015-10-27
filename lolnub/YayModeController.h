//
//  YayModeController.h
//  lolnub
//
//  Created by Anonymous on 10/18/12.
//  Copyright (c) 2012 lolnub.com. All rights reserved.
//

#import "ModeController.h"
#import "NubSpecialView.h"
#import "NubItemView.h"

@interface YayModeController : ModeController<NSTableViewDataSource, NSTableViewDelegate>

@property (assign) NSInteger                    goldenIndex;
@property (strong) NubItem                      *goldenItem;

@property (strong) IBOutlet NubSpecialView      *goldenView;
@property (weak) IBOutlet NSMenu                *goldenContextMenu;
@property (weak) IBOutlet NSTableView           *goldenTable;
@property (weak) IBOutlet NSTextField           *goldenNubcake;

@property (weak) IBOutlet NubItemView           *itemView;

- (void)reloadData;

- (void)addYayItems:(NSArray *)items;
- (IBAction)removeYayItem:(id)sender;
- (IBAction)updateYayItems:(id)sender;

- (IBAction)pingYayItems:(id)sender;
- (IBAction)beamYayItems:(id)sender;

@end


