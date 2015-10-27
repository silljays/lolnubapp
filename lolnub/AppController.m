//
//  AppController.m
//  lolnub
//
//  Created by Me on 10/13/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "AppController.h"
#import "sys/sysctl.h"

static AppController *instance = nil;

@interface AppController (Private)

- (void)x_panic;
- (void)x_staleVersionCheck;

@end

@implementation AppController


+ (AppController*)sharedAppController {
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    
    return instance;
}

- (instancetype)init {
    if (instance == nil) {
        instance = [super init];
    }
    
    return instance;
}

- (void)awakeFromNib {
    // do NOT open automatically.
    [[NSApplication sharedApplication] disableRelaunchOnLogin];
    
    // shutdown the app under various power/sleep notifications
    NSNotificationCenter *workspaceNoteCenter = [NSWorkspace sharedWorkspace].notificationCenter;
    
    SEL panicSelector = @selector(x_panic);
    
    [workspaceNoteCenter addObserver:self selector:panicSelector name:NSWorkspaceWillPowerOffNotification		object:nil];
    [workspaceNoteCenter addObserver:self selector:panicSelector name:NSWorkspaceWillSleepNotification			object:nil];
    [workspaceNoteCenter addObserver:self selector:panicSelector name:NSWorkspaceScreensDidSleepNotification	object:nil];
    
//#ifdef CHECK_VERSION
//    [self performSelectorInBackground:@selector(x_staleVersionCheck) withObject:nil];
//#endif
    
    // hack: force eject nubs on app start in case of a previous crash,
    // otherwise the lil nubies get wedged until logout.. :(
    NSString *command = @"hdiutil info | grep .nub | grep \\/dev | awk '{ print $3 }' | xargs hdiutil unmount -force";
    system(command.UTF8String);
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self.documents makeObjectsPerformSelector:@selector(close:) withObject:self];
}

- (IBAction)openDocument:(id)sender {
    [super openDocument:sender];
}

- (IBAction)newQuickDocument:(id)sender {
    [EncryptMode quickCreateNub:[sender identifier]];
}


#pragma mark General

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    return YES;
}

- (void)alert:(NSString *)message info:(NSString *)info style:(NSAlertStyle)style {
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert addButtonWithTitle:@"Quit"];
    alert.messageText = message;
    alert.informativeText = info;
    alert.alertStyle = style;
    
    [alert runModal];
}

- (IBAction)panic:(id)sender {
    [self x_panic];
}


#pragma mark Links

- (IBAction)openDefaultURI:(id)sender {
    [[EncryptMode quickCreateNub:@"folder"] setMode:WebBucketMode actionCallback:^(WebMode *webMode) {
        webMode.nubspace = DEFAULT_URI;
        [webMode reloadData];
    }];
}

- (IBAction)openSupportURI:(id)sender {
    [[EncryptMode quickCreateNub:@"folder"] setMode:WebBucketMode actionCallback:^(WebMode *webMode) {
        webMode.nubspace = URI_SUPPORT;
        [webMode reloadData];
    }];
}

- (IBAction)openPrivacyURI:(id)sender {
    [[EncryptMode quickCreateNub:@"folder"] setMode:WebBucketMode actionCallback:^(WebMode *webMode) {
        webMode.nubspace = URI_PRIVACY;
        [webMode reloadData];
    }];
}

- (void)dealloc {
    // remove workspace notes
    [[NSWorkspace sharedWorkspace].notificationCenter removeObserver:self];
    
    // remove app (internal) notes
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


@implementation AppController (Private)

- (void)x_panic {
    [[NSApplication sharedApplication] hide:nil];
    
    // panic's will NOT cleanly close their documents… #todo: more thought into this.. suggestions?
    //[self.documents makeObjectsPerformSelector:@selector(close:) withObject:self];
    
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)x_staleVersionCheck {
    sleep(30);
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    
    [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URI_VERSION]] returningResponse:&response error:&error];
    
    // verify that export path is not a path of the current Nub
    if (response.statusCode != 200) {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert addButtonWithTitle:@"Lets get them."];
        alert.messageText = @"Hey this version is broke.";
        alert.informativeText = @"It's pretty bad, they were even making fun of this build on some forums earlier. Why don't you grab the newest release and together, we'll put a stop to those little shits.";
        alert.alertStyle = NSInformationalAlertStyle;
        
        [alert runModal];
    }
}

@end
