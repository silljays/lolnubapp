//
//  NubBrandView.m
//  lolnub
//
//  Created by Anonymous on 8/2/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "NubBrandView.h"


@implementation NubBrandView

@synthesize brandColor;


- (void)awakeFromNib {
    NSColor *startColor = [NSColor blackColor];
    startColor = [startColor blendedColorWithFraction:0.42 ofColor:[NSColor lightGrayColor]];
    startColor = [startColor colorWithAlphaComponent:0.6];
    self.gradientStartColor = startColor;

    NSColor *stopColor = [NSColor blackColor];
    stopColor = [stopColor blendedColorWithFraction:0.0033 ofColor:[NSColor prettyBlue]];
    stopColor = [stopColor colorWithAlphaComponent:0.3];
    self.gradientStopColor = stopColor;
}

- (BOOL)allowsVibrancy {
    return YES;
}

- (BOOL)wantsDefaultDrawRect {
    return YES;
}

- (BOOL)wantsDefaultClipping {
    return YES;
}

- (BOOL)isOpaque {
    return NO;
}

- (BOOL)autoresizesSubviews {
    return YES;
}

- (NSAutoresizingMaskOptions)autoresizingMask {
    return (NSViewWidthSizable | NSViewHeightSizable);
}

- (CGFloat)gradientAngle {
    return 90.0;
}

- (NSRect)gradientRect {
    NSRect boundsRect = self.bounds;

    return NSMakeRect(-800.0, boundsRect.origin.y, boundsRect.size.width + 1600.0, boundsRect.size.height);
}

- (NSBezierPath *)clipPath {
    // clip the path to get our rounded-style window
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:CLIP_RADIUS yRadius:CLIP_RADIUS];
    
    [clipPath addClip];
    
    return clipPath;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *insetPath = [self clipPath];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    
    shadow.shadowOffset = NSMakeSize(0.0, 22.0);
    shadow.shadowBlurRadius = 20.0;
    shadow.shadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.96];
    [shadow set];
    
    [[[NSColor blackColor] colorWithAlphaComponent:0.66] set];
    [insetPath fill];

//    // inset the pattern rect by a few pixels to fix the pixels from smearing the rounded corners of the view's window
//    [[NSColor colorWithPatternImage:[NSImage imageNamed:WALLPAPER_FILENAME]] set];
//    [insetPath fill];

    [[[NSGradient alloc] initWithStartingColor:self.gradientStartColor endingColor:self.gradientStopColor]
        drawInBezierPath:insetPath relativeCenterPosition:NSZeroPoint];
    
    [[[[NSColor whiteColor] blendedColorWithFraction:0.22 ofColor:[NSColor prettyBlue]] colorWithAlphaComponent:0.33] set];
    [insetPath stroke];
}

@end
