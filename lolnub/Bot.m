//
//  Bot.m
//  lolnub
//
//  Created by Anonymous on 9/26/10.
//  Copyright 2014 the lolnub project. All rights reserved.
//

#import "Bot.h"

#define KEY_POST_NAME            @"postName"
#define KEY_POST_STRING          @"postString"
#define KEY_POST_ITEM            @"postItem"

#define BOUNDARY                 @"----NUBAppsFormBoundaryByUploader"


NSString *const BotDidBecomeReadyNotification       = @"BotDidBecomeReadyNotification";
NSString *const BotDidFinishNotification			= @"BotDidFinishNotification";
NSString *const BotDidBeamtoURINotification         = @"BotDidBeamtoURINotification";

@implementation Bot

@synthesize owner;
@synthesize title;
@synthesize operation;
@synthesize isTransient;
//@synthesize delegate = delegate_;

- (instancetype)init {
    self = [super init];
    if (self) {
        postStrings = [[NSMutableArray alloc] initWithCapacity:0];
        postItems = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

+ (Bot *)botWithOwner:(id)owner title:(NSString *)title transient:(BOOL)transient block:(void (^)(void))block {
    @throw @"lol no bots here";
    
    Bot *bot = [[Bot alloc] init];
    
    bot.owner = owner;
    bot.title = title;
    bot.isTransient = transient;
    
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:block];
    operation.completionBlock = ^(void){
        [[NSNotificationCenter defaultCenter] postNotificationName:BotDidFinishNotification object:bot];
    };
    
    bot.operation = operation;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BotDidBecomeReadyNotification object:bot];
    
    return bot;
}

- (void)addParamToPOST:(NSString *)stringValue withKeyName:(NSString *)postName {
    NSDictionary *stringDictionary;
    stringDictionary = @{KEY_POST_STRING: stringValue, KEY_POST_NAME: postName};
    [postStrings addObject:stringDictionary];
}

- (void)addItemToPOST:(NubItem *)item {
    if (item) {
        [postItems addObject:item];
    }
}

- (void)beamToURI:(NSURL *)uri {
    // uploads are background only
    if ([[NSThread currentThread] isMainThread]) {
        [self performSelectorInBackground:@selector(beamToURI:) withObject:uri];
        return;
    }
    
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    
    NSMutableData *postData = [[NSMutableData alloc] init];
    
    // Post data.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:uri
                                                                cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                            timeoutInterval:30];
    
    // Create string data.
    for (NSDictionary *params in postStrings) {
        [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", @"code"] dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[[NSString stringWithFormat:@"%@\r\n", params[KEY_POST_STRING]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    for (NubItem *item in postItems) {
        // upload the item
        [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", @"data", item.nubspace]
                              dataUsingEncoding:NSUTF8StringEncoding]];
        
        [postData appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", @"multipart/mixed"] dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[NSData dataWithContentsOfFile:item.path]];
        [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        [postData appendData:[[NSString stringWithFormat:@"--%@--\r\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
        
        request.HTTPMethod = @"POST";
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];
        [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", BOUNDARY] forHTTPHeaderField:@"Content-Type"];
    }
    
    request.HTTPBody = postData;
    
    [NSThread sleepForTimeInterval:0.3];
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BotDidBeamtoURINotification object:uri];
    }] resume];
}

@end
