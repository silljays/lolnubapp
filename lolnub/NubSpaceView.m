//
//  NubSpaceView.h
//  lolnub
//
//  Created by Anonymous on 1/9/14.
//  Copyright (c) 2015 lolnub developers. All rights reserved.
//

#import "NubSpaceView.h"

#define CLIP_RADIUS                     0

@implementation NubSpaceView

- (BOOL)mouseDownCanMoveWindow {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Save
    NSGraphicsContext *graphics = [NSGraphicsContext currentContext];
    [graphics saveGraphicsState];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    
    shadow.shadowOffset = NSMakeSize(0.0, -1.0);
    shadow.shadowBlurRadius = 3.0;
    shadow.shadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.77];
    [shadow set];
    
    // Background
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:CLIP_RADIUS yRadius:CLIP_RADIUS];
    
    NSColor *backColor = [NSColor blackColor];
    [backColor set];
    [path fill];
    
    backColor = [[NSColor darkGrayColor] colorWithAlphaComponent:0.33];
    [backColor set];
    [path fill];
    
    // Restore
    [graphics restoreGraphicsState];
}

@end
