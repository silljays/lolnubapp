//
//  NubWindowController.m
//  lolnub
//
//  Created by Anonymous on 10/31/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "NubWindowController.h"

@implementation NubWindowController

@synthesize panicButton, closeButton, minimizeButton, zoomButton;

- (BOOL)shouldCloseDocument {
    return YES;
}

- (IBAction)close:(id)sender {
    [self.window close];
}

- (id)nub {
    return self.owner;
}

- (BOOL)shouldCascadeWindows {
    return YES;
}

- (void)awakeFromNib {
    NSWindow *bucketWindow = self.window;
    
    panicButton.actionCallback = ^(id sender){
        [[AppController sharedAppController] panic:nil];
    };
    panicButton.gradientBaseColor = [NSColor magentaColor];
    
    closeButton.actionCallback = ^(id sender){
        [bucketWindow close];
    };
    closeButton.gradientBaseColor = [NSColor redColor];

    minimizeButton.actionCallback = ^(id sender){
        [bucketWindow performMiniaturize:self];
    };
    minimizeButton.gradientBaseColor = [NSColor yellowColor];

    zoomButton.actionCallback = ^(id sender){
        [bucketWindow performZoom:self];
    };
    zoomButton.gradientBaseColor = [[NSColor greenColor] blendedColorWithFraction:0.22 ofColor:[NSColor prettyBlue]];
}

- (IBAction)performMiniaturize:(id)sender {
    [[self.nub window] miniaturize:sender];
}

@end
