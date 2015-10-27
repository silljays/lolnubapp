//
//  NubMedia.h
//  lolnub
//
//  Created by Anonymous on 8/27/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <QTKit/QTKit.h>
#import "NubMediaView.h"

@interface NubMedia : NSWindowController

@property (strong)  IBOutlet NubItem        *mediaItem;

@property (strong)  IBOutlet NSWindow       *imageWindow;
@property (strong)  IBOutlet NubMediaView   *imageView;

@property (strong)  IBOutlet NSWindow       *movieWindow;
@property (strong)  IBOutlet QTMovieView    *movieView;

@property (strong)  IBOutlet NSWindow       *textWindow;
@property (strong)  IBOutlet NSTextView     *textView;

- (void)openItem:(NubItem *)item;

- (IBAction)close:(id)sender;

- (NSWindow *)activeWindow;

@end
