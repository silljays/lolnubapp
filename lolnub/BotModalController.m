//
//  BotModalController.m
//  lolnub
//
//  Created by Anonymous on 9/26/10.
//  Copyright 2014 the lolnub project. All rights reserved.
//

#import "BotModalController.h"

@implementation BotModalController

@synthesize modalSession;
@synthesize modalBot;

@synthesize modalBotPanel;
@synthesize modalBotProgress;

- (instancetype)init {
	self = [super init];
	
	if (self) {
		NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
		
		[noteCenter addObserver:self selector:@selector(startBotModal:) name:BotModalWillStartNotification object:nil];
		[noteCenter addObserver:self selector:@selector(removeBotModal:) name:BotModalDidFinishNotification object:nil];
	}
	
	return self;
}

- (void)finalize {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super finalize];
}

#pragma mark API

- (void)startBotModal:(NSNotification *)notification {
    @synchronized(self) {
        self.modalBot = notification.object;
        
        [modalBotProgress setUsesThreadedAnimation:YES];
        [modalBotProgress startAnimation:self];
        [modalBotPanel makeKeyAndOrderFront:self];
    }
}

- (void)removeBotModal:(NSNotification *)notification {    
	[modalBotPanel orderOut:self];
	[modalBotProgress stopAnimation:self];
    
	[self setModalBot:nil];
}

@end
