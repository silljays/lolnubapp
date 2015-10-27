//
//  BotModalController.h
//  lolnub
//
//  Created by Anonymous on 9/26/10.
//  Copyright 2014 the lolnub project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BotModal.h"

@interface BotModalController : NSObject {}

@property (assign) NSModalSession				modalSession;
@property (strong) BotModal                     *modalBot;
@property (strong) IBOutlet NSPanel				*modalBotPanel;
@property (strong) IBOutlet NSProgressIndicator	*modalBotProgress;

- (void)startBotModal:(NSNotification *)notification;
- (void)removeBotModal:(NSNotification *)notification;

@end
