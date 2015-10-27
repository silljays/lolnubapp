//
//  NubMode.h
//  lolnub
//
//  Created by Anonymous on 11/15/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "ModeController.h"
#import "NubItemSource.h"
#import "NubItemView.h"
#import "NubMediaView.h"

extern NSString *const BucketSessionDidImportPathsNotification;

@interface NubMode : ModeController<NSURLSessionDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>

@property (strong)              NubItemSource               *itemSource;
@property (strong)              NSMutableArray              *items;
@property (strong)              IBOutlet NubItemView        *itemView;
@property (strong)              IBOutlet NSTextField        *feedback;

@property (strong)              IBOutlet NSPopUpButton      *sessionArrangeBy;
@property (strong)              IBOutlet NSPopUpButton      *sessionOrderBy;
@property (strong)              IBOutlet NSPopUpButton      *sessionLimit;

@property (strong)              IBOutlet NSMenu             *itemContextMenu;

@property (strong)              IBOutlet NSTextField        *itemName;
@property (strong)              IBOutlet NSTextField        *itemCode;

- (IBAction)createItem:(id)sender;
- (IBAction)openSelectedItems:(id)sender;

- (NSUInteger)itemRating;
- (IBAction)setItemRating:(id)sender;
- (IBAction)setDesktopPicture:(id)sender;

@end
