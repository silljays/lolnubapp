//
//  NubSpecialView.m
//  lolnub
//
//  Created by Anonymous on 10/18/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "NubMediaView.h"

#define DEFAULT_SIZE 512.0

@implementation NubMediaView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    
    if (self) {
        self.autoresizes        = YES;
        self.backgroundColor    = [NSColor blackColor];
        
		[self registerForDraggedTypes:@[NSFilenamesPboardType]];
    }
    
    return self;
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)local {
	return [self.delegate draggingSourceOperationMaskForLocal:local];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return [self.delegate draggingEntered:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    return [self.delegate performDragOperation:sender];
}

- (void)mouseDown:(NSEvent *)event {
    [super mouseDown:event];
}

- (void)rightMouseDown:(NSEvent *)event {
    // clear the mouse down tracking to prevent right clicks from triggering double-clicks
    self.lastMouseDownPoint = NSZeroPoint;
    self.lastMouseDownTime = 0;
    
    [self mouseDown:event];
    [super rightMouseDown:event];
    
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)event {
	[self setDragging:NO];
	self.dragRect = NSZeroRect;
    
	[super mouseUp:event];
    
    [self setNeedsDisplay:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NubItemViewSelectionDidChangeNotification object:self];
}

- (void)mouseDragged:(NSEvent *)event {
	[self autoscroll:event];
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
	return [self.delegate menuForEvent:event];
}

- (void)setImageFromImage:(NSImage *)newImage {    
    if (!newImage) {
        return;
    }

    NSRect boundsRect = self.bounds;
    
    newImage.size = boundsRect.size;
    
    [self setImage:[newImage CGImageForProposedRect:&boundsRect context:NULL hints:NULL] imageProperties:NULL];
    
    [self zoomImageToFit:self];
}

- (void)setImageFromItem:(NubItem *)newItem {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif

    if (!newItem || !newItem.path) {
        return;
    }

    [self setImageFromImage:[[NSImage alloc] initByReferencingURL:[[NSURL alloc] initFileURLWithPath:newItem.path isDirectory:NO]]];
}

@end
