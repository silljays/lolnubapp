//
//  NubTrafficButton.m
//  lolnub
//
//  Created by Anonymous on 11/9/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#undef  DEBUG_CAVEMAN
#define EVENT_SENDER_KEY    @"s"
#define EVENT_KEY           @"e"

#define FUDGEX              0.5
#define FUDGEY              1.0

#import "NubBrandTrafficButton.h"

NSString *const NubBrandTrafficButtonMouseEnteredNotification   = @"NubBrandTrafficButtonMouseEnteredNotification";
NSString *const NubBrandTrafficButtonMouseExitedNotification    = @"NubBrandTrafficButtonMouseExitedNotification";

@implementation NubBrandTrafficButton

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.gradientBaseColor = [NSColor lightGrayColor];
        self.image = [NSImage imageNamed:self.imageName];
    }
    
    return self;
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    
    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
        
    [noteCenter addObserver:self selector:@selector(remoteMouseEntered:)    name:NubBrandTrafficButtonMouseEnteredNotification  object:self.superview];
    [noteCenter addObserver:self selector:@selector(remoteMouseExited:)     name:NubBrandTrafficButtonMouseExitedNotification   object:self.superview];
}

- (void)removeFromSuperview {
    [self.superview removeTrackingRect:self.trackingRectTag];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)wantsDefaultDrawRect {
    return NO;
}

- (NSBezierPath *)clipPath {
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(self.bounds, 1.0, 1.0)];
    
    [clipPath addClip];
    
    return clipPath;
}

- (NSColor *)gradientStartColor {
    return [self.gradientBaseColor blendedColorWithFraction:0.25 ofColor:[NSColor whiteColor]];
}

- (NSColor *)gradientStopColor {
    return [self.gradientBaseColor blendedColorWithFraction:0.25 ofColor:[NSColor lightGrayColor]];
}

- (void)drawBackgroundInRect:(NSRect)backgroundRect {
    NSGraphicsContext *graphics = [NSGraphicsContext currentContext];
    [graphics saveGraphicsState];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    
    shadow.shadowOffset = NSMakeSize(0.0, 0.0);
    if (self.isHovering) {
        shadow.shadowBlurRadius = 3.0;
        shadow.shadowColor = [[NSColor darkGrayColor] colorWithAlphaComponent:0.3];
    }
    else {
        shadow.shadowBlurRadius = 8.0;
        shadow.shadowColor = [[NSColor darkGrayColor] colorWithAlphaComponent:0.3];
    }
    [shadow set];
    
    NSColor *baseColor = self.gradientBaseColor;
    
    NSBezierPath *clipPath = self.clipPath;
    NSBezierPath *backPath = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(clipPath.bounds, 2.0, 2.0)];
    
    [[[NSColor darkGrayColor] blendedColorWithFraction:0.13 ofColor:baseColor] set];
    [backPath fill];

    CGFloat startFill, endFill = 0.0;
    
    if (self.isHovering) {
        startFill   = 1.0;
        endFill     = 1.0;
        
        [[[NSGradient alloc] initWithStartingColor:[baseColor colorWithAlphaComponent:startFill]
                                       endingColor:[baseColor colorWithAlphaComponent:endFill]]
         drawInBezierPath:backPath
         relativeCenterPosition:NSMakePoint(0.0, 0.0)];
    }
    else {
        startFill   = 0.9;
        endFill     = 0.85;
        
        [[[NSGradient alloc] initWithStartingColor:[baseColor colorWithAlphaComponent:startFill]
                                       endingColor:[baseColor colorWithAlphaComponent:endFill]]
         drawInBezierPath:backPath
         relativeCenterPosition:NSMakePoint(0.0, 0.0)];
    }

    [graphics restoreGraphicsState];
}

- (void)drawImageInRect:(NSRect)imageRect {
    if (self.isHidden || !self.isHovering) {
        return;
    }
    
    NSImage *hoverImage = self.image;

    NSShadow *shadow = [[NSShadow alloc] init];

    shadow.shadowOffset = NSMakeSize(0.0, 0.0);
    shadow.shadowBlurRadius = 10.0;
    shadow.shadowColor = [self.gradientBaseColor blendedColorWithFraction:0.33 ofColor:[NSColor whiteColor]];
    [shadow set];
    
    NSRect fixRect = NSInsetRect(imageRect, 5.0, 5.0);
    fixRect.origin.x += FUDGEX;
    
    [hoverImage drawInRect:fixRect fromRect:NSMakeRect(0.0, 0.0, hoverImage.size.width, hoverImage.size.height) operation:NSCompositeSourceOver fraction:0.8];
}

- (void)drawLabelInRect:(NSRect)labelRect {
    // noop
}

- (void)mouseEntered:(NSEvent *)theEvent {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    self.isHovering = YES;
    
    self.image = [NSImage imageNamed:[self.imageName stringByAppendingString:@"-hover"]];
    [super mouseEntered:theEvent];

    if (!self.isRemote) {
        [self x_noteMouseEvent:theEvent];
    }
    
    [self setNeedsDisplay];
}

- (void)mouseExited:(NSEvent *)theEvent {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    self.isHovering = NO;
    
    self.image = nil;
    [super mouseExited:theEvent];
    
    if (!self.isRemote) {
        [self x_noteMouseEvent:theEvent];
    }
    
    [self setNeedsDisplay];
}

- (void)remoteMouseEntered:(NSNotification *)note {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    if (note.userInfo[EVENT_SENDER_KEY] == self) {
        return;
    }
    
    NSEvent *theEvent = note.userInfo[EVENT_KEY];
    
    if (!theEvent) {
        return;
    }
    
    self.isRemote = YES;
    [self mouseEntered:theEvent];
    self.isRemote = NO;
}

- (void)remoteMouseExited:(NSNotification *)note {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    if (note.userInfo[EVENT_SENDER_KEY] == self) {
        return;
    }
    
    NSEvent *theEvent = note.userInfo[EVENT_KEY];
    
    if (!theEvent) {
        return;
    }
    
    self.isRemote = YES;
    [self mouseExited:theEvent];
    self.isRemote = NO;
}

- (void)x_noteMouseEvent:(NSEvent *)theEvent {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    NSString *noteName = nil;

    if (theEvent.type == NSMouseEntered) {
        noteName = NubBrandTrafficButtonMouseEnteredNotification;
    }
    else if (theEvent.type == NSMouseExited) {
        noteName = NubBrandTrafficButtonMouseExitedNotification;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:noteName object:self.superview userInfo:@{EVENT_SENDER_KEY : self, EVENT_KEY : theEvent}];
}

@end
