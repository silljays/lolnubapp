//
//  BotModal.m
//  lolnub
//
//  Created by Anonymous on 9/26/10.
//  Copyright 2014 the lolnub project. All rights reserved.
//

#import "BotModal.h"

NSString *const BotModalWillStartNotification			= @"BotModalWillStartNotification";
NSString *const BotModalDidFinishNotification			= @"BotModalDidFinishNotification";

@implementation BotModal

+ (void)startBotModalWithTitle:(NSString *)title block:(void (^)(void))block {
//	BotModal *modalBot = [[BotModal alloc] init];
//	
//	modalBot.title = title;
//	modalBot.operation = [NSBlockOperation blockOperationWithBlock:block];
//	modalBot.operation.completionBlock = ^(void){
//		[[NSNotificationCenter defaultCenter] postNotificationName:BotModalDidFinishNotification object:modalBot];
//	};
//		
//	[[NSNotificationCenter defaultCenter] postNotificationName:BotModalWillStartNotification object:modalBot];
//	
//	[modalBot.operation start];
//	[modalBot.operation waitUntilFinished];
}

@end
