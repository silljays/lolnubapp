//
//  WebMode.m
//  lolnub
//
//  Created by Anonymous on 7/26/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "WebMode.h"


#define DEFAULT_WEB_URI @"https://localhost:8443/"


@implementation WebMode

@synthesize webView;


#pragma mark ModeController

- (NSString *)modeName {
    return @"web";
}

- (BOOL)isAdminMode {
    return NO;
}

- (BOOL)isSingleton {
    return NO;
}

- (void)awakeFromNib {
    self.view = self.webView;
}

- (void)afterAwakeFromNib {
    self.webView.downloadDelegate = self;
    self.webView.UIDelegate = self;
    
    NSScrollView* scrollView = (self.webView).mainFrame.frameView.documentView.enclosingScrollView;
    
    [scrollView.verticalScroller setHidden:YES];
    [scrollView.horizontalScroller setHidden:YES];

    
    [self performNubspace:self];
}

- (void)fullyAwake {
    [super fullyAwake];
    
    NSString *nubspace = (self.webView).mainFrameURL;
    
    if (!nubspace || [nubspace isEqualToString:@"about:blank"]) {
        nubspace = DEFAULT_WEB_URI;
    }
    
    self.nub.nubspaceView.stringValue = nubspace;
    
    [self.view display];
}

- (void)performNubspace:(id)sender {
    if (!self.nub.nubspaceView.stringValue || [self.nub.nubspaceView.stringValue isEqualToString:@""]) {
        self.nub.nubspaceView.stringValue = DEFAULT_WEB_URI;
    }
    
    // only support HTTPS
    if ([self.nub.nubspaceView.stringValue hasPrefix:@"http://"]) {
        self.nub.nubspaceView.stringValue = [self.nub.nubspaceView.stringValue stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
    }
    
    // ignore caches for direct network access
    [(self.webView).mainFrame loadRequest:
     [NSURLRequest requestWithURL: [NSURL URLWithString:self.nub.nubspaceView.stringValue]
                      cachePolicy: NSURLRequestReloadIgnoringCacheData
                  timeoutInterval: 10.0]];
}

- (void)reloadData {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        
        return;
    }
    
    [self performNubspace:self];
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
    return self.itemContextMenu;
}

#pragma mark WebModeController

- (IBAction)openInternal:(id)sender {
    [self.delegate setMode:NubBucketMode actionCallback:^(NubMode *nubMode) {
    }];
}

- (IBAction)openExternal:(id)sender {
    [self downloadInternal:sender];
    
    [self.delegate setMode:BotBucketMode actionCallback:^(BotMode *botMode) {}];
}

- (IBAction)openDefaultURI:(id)sender {
    self.nubspace = DEFAULT_URI;
    
    [self performNubspace:sender];
}

- (IBAction)downloadInternal:(id)sender {
    NSURL *elementURL = self.clickedElement[@"WebElementImageURL"];
    
    if (!elementURL) {
        NSBeep();
        return;
    }
    
    NSURLRequest  *elementRequest  = [NSURLRequest requestWithURL:elementURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
    NSURLDownload *elementDownload = [[NSURLDownload alloc] initWithRequest:elementRequest delegate:self];
    
    if (elementDownload) {
        [elementDownload setDeletesFileUponFailure:YES];
    }
    
    [self download:elementDownload decideDestinationWithSuggestedFilename:@"untitled"];
}

//- (IBAction)downloadExternal:(id)sender {
//    DebugLog();
//    NSLog(@"sender: %@", sender);
//    NSBeep();
//}

#pragma mark WebView UIDelegate

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename {
    NSString *destinationFilename = nil;
    
    destinationFilename = [[self x_downloadPath] stringByAppendingPathComponent:filename];
    
    [download setDestination:destinationFilename allowOverwrite:NO];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    NSBeep();
    NSLog(@"***error: %@", error);
    
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert addButtonWithTitle:@"OK"];
    alert.messageText = @"Broke Download...";
    alert.informativeText = @"Unknown Download type, the net might be down, or the server crashed. Try again or contact support.";
    alert.alertStyle = NSInformationalAlertStyle;
    
    [alert runModal];
}

- (void)downloadDidFinish:(NSURLDownload *)download {
    DebugLog();
    
    NSString *downloadFile = download.request.URL.path.lastPathComponent;
    NSString *downloadPath = [[self x_downloadPath] stringByAppendingPathComponent:downloadFile];
    
    [self.delegate.bucketManager importPaths:@[downloadPath]];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
    self.clickedElement = element;
    
    return @[];
}

- (NSString *)x_downloadPath {
    return self.delegate.bucketManager.rootPath;
}

@end
