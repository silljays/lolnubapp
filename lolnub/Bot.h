//
//  Bot.h
//  lolnub
//
//  Created by Anonymous on 9/26/10.
//  Copyright 2014 the lolnub project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Bot.h"
#import "NubItem.h"

extern NSString *const BotDidBecomeReadyNotification;
extern NSString *const BotDidFinishNotification;
extern NSString *const BotDidBeamtoURINotification;

@interface Bot : NSObject {
    NSMutableArray *postStrings;
    NSMutableArray *postItems;
}
@property (assign) id			owner;
@property (strong) NSString		*title;
@property (strong) NSOperation	*operation;
@property (assign) BOOL         isTransient;
//@property (nonatomic, assign) id <BotDelegate> delegate;

+ (instancetype)botWithOwner:(id)owner title:(NSString *)title transient:(BOOL)transient block:(void (^)(void))block;

- (void)addParamToPOST:(NSString *)stringValue withKeyName:(NSString *)postName;
- (void)addItemToPOST:(NubItem *)item;

- (void)beamToURI:(NSURL *)uri;

@end
