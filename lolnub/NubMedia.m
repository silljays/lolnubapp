//
//  NubMedia.m
//  lolnub
//
//  Created by Anonymous on 8/27/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "NubMedia.h"

@implementation NubMedia

@synthesize mediaItem;
@synthesize imageView;
@synthesize imageWindow;
@synthesize movieView;
@synthesize movieWindow;

- (void)awakeFromNib {
    self.imageWindow.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    self.movieWindow.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    self.textWindow.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
}

- (BOOL)shouldCascadeWindows {
    return YES;
}

- (NSWindow *)activeWindow {
    if (imageWindow.visible) {
        return imageWindow;
    }
    else {
        return movieWindow;
    }
}

- (void)performNubspace:(id)sender {
    NSBeep();
}

- (IBAction)close:(id)sender {
    [imageWindow close];
    [movieWindow close];
}

- (void)openItem:(NubItem *)item {
    self.mediaItem = item;
    
    if (!item.isFresh) {
        [item refresh];
    }
    [item wasJustOpened];
    
    switch ((item.mediaKind).integerValue) {
        case NubItemMediaKindImage:
            [self x_openImage:item];
            break;
            
        case NubItemMediaKindMovie:
            [self x_openMovie:item];
            break;
            
        default:
            [self x_openText:item];
            break;
    }
}

- (void)keyDown:(NSEvent *)event {    
    if ([event.charactersIgnoringModifiers isEqualToString:@" "]) {
        [self close];
    }
}

- (void)x_openImage:(NubItem *)imageItem {
    NSImage *image = [[NSImage alloc] initByReferencingURL:[[NSURL alloc] initFileURLWithPath:imageItem.path isDirectory:NO]];

    NSRect frameRect = self.imageWindow.frame;
    NSSize imageSize = [image bestRepresentationForRect:frameRect context:NULL hints:NULL].size;
    
    [imageView setImageFromItem:imageItem];
    
    [imageWindow setFrame:NSMakeRect(frameRect.origin.x, frameRect.origin.y, imageSize.width, imageSize.height) display:YES animate:YES];
    imageWindow.title = imageItem.nubspace;

    [imageWindow makeKeyAndOrderFront:self];
    [imageView display];
}

- (void)x_openMovie:(NubItem *)movieItem {
    // todo: fix deprecations for movies
    QTMovie *movie = [QTMovie movieWithURL:[[NSURL alloc] initFileURLWithPath:movieItem.path isDirectory:NO] error:NULL];

    [movieView setMovie:movie];
    
    movieWindow.title = movieItem.nubspace;
    [movieWindow makeKeyAndOrderFront:self];
    [movieView display];
    
}

- (void)x_openText:(NubItem *)textItem {
    // todo: fix deprecations for movies

    self.textWindow.title = textItem.nubspace;
    self.textView.string = [NSString stringWithContentsOfFile:textItem.path encoding:NSUTF8StringEncoding error:NULL];
    
    [self.textWindow makeKeyAndOrderFront:self];
}

@end
