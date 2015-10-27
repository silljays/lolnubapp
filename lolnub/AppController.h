//
//  AppController.h
//  lolnub
//
//  Created by Me on 10/13/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//


#import <Foundation/Foundation.h>
#import "BotController.h"
#import "BotModalController.h"

@interface AppController : NSDocumentController

@property (strong) IBOutlet BotController			*botController;
@property (strong) IBOutlet BotModalController      *botModalController;

// singleton
+ (AppController*)sharedAppController;

// generic quick method for alerts
- (void)alert:(NSString *)message info:(NSString *)info style:(NSAlertStyle)style;

// quit the app as quick as possible
- (IBAction)panic:(id)sender;

- (IBAction)newQuickDocument:(id)sender;

// open a link to the cloud
- (IBAction)openDefaultURI:(id)sender;
// open a link to the support site
- (IBAction)openSupportURI:(id)sender;
// open a link to the support site
- (IBAction)openPrivacyURI:(id)sender;

@end
