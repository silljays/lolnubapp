//
//  BotModal.h
//  lolnub
//
//  Created by Anonymous on 9/26/10.
//  Copyright 2014 the lolnub project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *const BotModalWillStartNotification;
extern NSString *const BotModalDidFinishNotification;

@interface BotModal : Bot {}

+ (void)startBotModalWithTitle:(NSString *)title block:(void (^)(void))block;

@end
