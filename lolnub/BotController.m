//
//  BotController.m
//  lolnub
//
//  Created by Anonymous on 8/19/10.
//  Copyright 2014 the lolnub project. All rights reserved.
//

#define AppPreferencePerformanceFactor @"todo"

#import "BotController.h"
#import <sys/param.h>
#import <sys/sysctl.h>

static BotController *instance = nil;

@interface BotController (Private)

// return the number of concurrent operations based on several performance factors
-(NSInteger)x_bestConcurrentOperationCount;

@end

@implementation BotController

@synthesize botQueue;
@synthesize bots;

@synthesize botPanel;
@synthesize botStatus;
@synthesize botProgress;
@synthesize botTable;
@synthesize botIndicator;

- (instancetype)init {
	if (instance == nil) {
		instance = [super init];
		
		self.botQueue = [[NSOperationQueue alloc] init];
        
		self.botQueue.maxConcurrentOperationCount = [self x_bestConcurrentOperationCount];
		
		self.bots = [NSMutableArray array];
	}
	
    return instance;
}

- (void)awakeFromNib {
	NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
	
	[noteCenter addObserver:self selector:@selector(addAndStartBot:)		name:BotDidBecomeReadyNotification	object:nil];
	[noteCenter addObserver:self selector:@selector(removeBot:)             name:BotDidFinishNotification		object:nil];
	[noteCenter addObserver:self selector:@selector(terminateAllBots)		name:NSApplicationWillTerminateNotification	object:nil];
	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults addObserver:self forKeyPath:AppPreferencePerformanceFactor options:NSKeyValueObservingOptionNew context:NULL];

	[botProgress setUsesThreadedAnimation:YES];
	[botIndicator setUsesThreadedAnimation:YES];
	
	[self updateBotStatus];
}

- (void)finalize {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super finalize];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	if([keyPath isEqualToString:AppPreferencePerformanceFactor]) {
		@synchronized(self) {
			self.botQueue.maxConcurrentOperationCount = self.x_bestConcurrentOperationCount;
		}

		[self updateBotStatus];
	}
}

#pragma mark API

- (void)addAndStartBot:(NSNotification *)notification {
	@synchronized(self) {
		Bot *bot = notification.object;
		
        @try {
            [bots addObject:bot];
            [self.botQueue addOperation:bot.operation];
        }
        @catch (NSException *exception) {
            
        }
	}
	
	//[botPanel orderFront:self];
	[self updateBotStatus];
}

- (void)removeBot:(NSNotification *)notification {
	@synchronized(self) {
		[bots removeObject:notification.object];
	}
	
	[self updateBotStatus];
}

- (void)cancelBotsWithOwner:(id)owner transient:(BOOL)transient {
	if (owner) {
		@synchronized(self) {
            NSMutableIndexSet *removeSet = [NSMutableIndexSet indexSet];
            
            [bots enumerateObjectsUsingBlock:^(id bot, NSUInteger index, BOOL *stop) {
				id botOwner = [bot owner];
				
				if (!botOwner || ([botOwner isEqual:owner] && ([bot isTransient] == transient))) {
					[[bot operation] cancel];
                    [removeSet addIndex:index];
				}
            }];
            
            [bots	removeObjectsAtIndexes:removeSet];
		}
		
		[self updateBotStatus];
	}
    else if (transient) {
        @synchronized(self) {
            NSMutableIndexSet *removeSet = [NSMutableIndexSet indexSet];
            
            [bots enumerateObjectsUsingBlock:^(id bot, NSUInteger index, BOOL *stop) {
                if ([bot isTransient]) {
                    [[bot operation] cancel];
                    [removeSet addIndex:index];
                }
            }];
            
            [bots	removeObjectsAtIndexes:removeSet];
        }
    }
	else {
		[self terminateAllBots];
	}
}

- (void)terminateAllBots {
	@synchronized(self) {
		[botQueue cancelAllOperations];
		[bots removeAllObjects];
	}
	
	[self updateBotStatus];
}

- (void)updateBotStatus {
	@synchronized(self) {
		[botTable reloadData];
    }
    
    if (bots.count > 0) {
        [botProgress startAnimation:self];
        [botIndicator startAnimation:self];
    }
    else {
        [botProgress stopAnimation:self];
        [botIndicator stopAnimation:self];
    }
    
    botStatus.stringValue = [NSString stringWithFormat:@"Bots: %ld tasks for %ld workers.", bots.count, (self.botQueue).maxConcurrentOperationCount];
}

#pragma mark Interface

- (IBAction)showBotPanel:(id)sender {
	[botPanel orderFront:self];
}

#pragma mark BotTableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return bots.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (row < 0 || row >= self.bots.count) {
		return nil;
	}
	
	if ([tableColumn.identifier isEqualToString:@"title"]) {
        NSString *title = nil;
        
        return title ? title : @"Loading";
	}
	
	return nil;
}

@end

@implementation BotController (Private)

- (NSInteger)x_bestConcurrentOperationCount {
	NSInteger count = 0;
	size_t size = sizeof(count);
	
    // return something small
	if (sysctlbyname("hw.logicalcpu", &count, &size, NULL, 0)) {
		count = 2;
	}
    else {
        // or something larger
        count = (NSInteger)lroundf(count * 0.5);
    }
    
    // fix the count if our rounding/calculation above bug out
    if (!count) {
        count = 1;
    }
	
	return count;
}

@end

