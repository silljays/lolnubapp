//
//  NubImageLabelButton.m
//  lolnub
//
//  Created by lolnub.com developers on 10/13/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#undef  DEBUG_CAVEMAN

#import "NubBrandButton.h"

#define GRADIENT_ANGLE              90.0
#define GRADIENT_OVERFLOW           160.0

#define LABEL_FONT_LARGE_SIZE       24.0

#define FUDGEY                      0.0

@implementation NubBrandButton

@synthesize image=x_image;
@synthesize imageName;
@synthesize imageCell;

@synthesize label;
@synthesize labelCell;

@synthesize actionCallback;
@synthesize trackingRectTag;

@synthesize isSpecial;

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.imageCell = [[NSImageCell alloc] init];
        imageCell.imageAlignment = NSImageAlignCenter;
		imageCell.imageScaling = NSImageScaleProportionallyUpOrDown;
        
        self.labelCell = [[NSTextFieldCell alloc] init];
        
		labelCell.alignment = NSCenterTextAlignment;
		labelCell.lineBreakMode = NSLineBreakByWordWrapping;
        
        labelCell.font = self.labelFont;
        labelCell.textColor = self.labelColor;
    }
    
    return self;
}

- (void)awakeFromNib {

}

- (void)viewDidMoveToWindow {
    // we want to receive mouseEntered/mouseExited events
    self.trackingRectTag = [self.superview addTrackingRect:self.frame owner:self userData:NULL assumeInside:YES];
}

- (void)dealloc {
    [self.superview removeTrackingRect:self.trackingRectTag];
}

- (BOOL)mouseDownCanMoveWindow {
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return YES;
}

- (void)setFrame:(NSRect)frameRect {
    [self.superview removeTrackingRect:self.trackingRectTag];
    
    super.frame = frameRect;
    
    self.trackingRectTag = [self.superview addTrackingRect:self.frame owner:self userData:NULL assumeInside:YES];
    
    [self setNeedsDisplay];
}

#pragma mark Customize

- (NSColor *)labelColor {
    return [[NSColor darkGrayColor] blendedColorWithFraction:0.65 ofColor:[NSColor purpleColor]];
}

- (NSFont *)labelFont {
    return [NSFont boldSystemFontOfSize:LABEL_FONT_LARGE_SIZE];
}

- (NSImage *)image {
    if (!x_image) {
        self.image = [NSImage imageNamed:self.imageName];
    }
    
    return x_image;
}

- (void)setImage:(NSImage *)newImage {    
    NSSize imageSize  = newImage.size;
    NSSize boundsSize = self.bounds.size;
    
    if (imageSize.width > boundsSize.width || imageSize.height > boundsSize.height) {
        newImage.size = boundsSize;
    }
    
    x_image = newImage;
}

- (NSString *)imageName {
    return self.identifier;
}

- (BOOL)autoresizesSubviews {
    return YES;
}

- (NSAutoresizingMaskOptions)autoresizingMask {
    return (NSViewWidthSizable | NSViewHeightSizable);
}

- (NSColor *)gradientStartColor {
    if (self.isSelected) {
        return [[NSColor prettyBlue] colorWithAlphaComponent:0.82];
    }
    
    return [[NSColor blackColor] colorWithAlphaComponent:0.22];
}

- (NSColor *)gradientStopColor {
    if (self.isSelected) {
        return [[NSColor prettyBlue] colorWithAlphaComponent:0.86];
    }
    return [[NSColor blackColor] colorWithAlphaComponent:0.16];
}

- (CGFloat)gradientAngle {
    return 90.0;
}

- (NSRect)gradientRect {
    return self.bounds;
}

- (NSBezierPath *)clipPath {
    // clip the path to get our rounded-style window if we are the size of the full window
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:CLIP_RADIUS yRadius:CLIP_RADIUS];
    [clipPath addClip];
    
    return clipPath;
}

- (BOOL)wantsDefaultDrawRect {
    return YES;
}

#pragma mark Rendering

- (void)drawRect:(NSRect)dirtyRect {
    if (self.isHidden) {
        return;
    }

    NSGraphicsContext *graphics = [NSGraphicsContext currentContext];
    [graphics saveGraphicsState];

    NSRect boundsRect = self.bounds;
    
    // optionally draw to super
    if (self.wantsDefaultDrawRect) {
        [super drawRect:dirtyRect];
    }
    
    // draw over the super rendering
    [self drawBackgroundInRect:dirtyRect];

    // now draw our image or label
    if (self.image) {
        [self drawImageInRect:boundsRect];
    }
    else {
        [self drawLabelInRect:boundsRect];
    }
    
    [graphics restoreGraphicsState];
}

- (void)drawBackgroundInRect:(NSRect)backgroundRect {
    NSGraphicsContext *graphics = [NSGraphicsContext currentContext];
    [graphics saveGraphicsState];

    NSBezierPath *backPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, FUDGEY, FUDGEY) xRadius:FUDGEY yRadius:FUDGEY];

    [[[NSColor blackColor] colorWithAlphaComponent:0.72] set];
    [backPath fill];
    
    [[[NSGradient alloc] initWithStartingColor:self.gradientStartColor
                                   endingColor:self.gradientStopColor
      ] drawInBezierPath:backPath
        relativeCenterPosition:NSMakePoint(0.0, 0.0)];
    
    [graphics restoreGraphicsState];
}

- (void)drawImageInRect:(NSRect)imageRect {
    if (self.isHidden) {
        return;
    }
    
    [self.image drawInRect:imageRect fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
}

- (NSRect)labelRectForRect:(NSRect)labelRect {
    NSSize labelSize = [self.labelCell cellSizeForBounds:labelRect];
    
    CGFloat selectedOffset = 0;
    
    NSRect actualRect = NSZeroRect;
    
    actualRect = NSMakeRect(labelRect.origin.x,
                            (labelRect.size.height / 2) - (labelSize.height / 2) + selectedOffset,
                            labelRect.size.width,
                            labelSize.height);
    
    return actualRect;
}

- (void)drawLabelInRect:(NSRect)labelRect {
    if (self.isHidden) {
        return;
    }
    
    if (self.toolTip) {
        NSShadow *shadow = [[NSShadow alloc] init];
        
        if (!self.isSelected) {
            shadow.shadowOffset = NSMakeSize(0.0, -1.0);
            shadow.shadowBlurRadius = 3.0;
            shadow.shadowColor = [[NSColor lightGrayColor] colorWithAlphaComponent:0.42];
            
            shadow.shadowColor = [[[NSColor darkGrayColor] blendedColorWithFraction:0.24 ofColor:[NSColor grayColor]] colorWithAlphaComponent:0.32];
        }
        else {
            shadow.shadowOffset = NSMakeSize(0.0, -1.0);
            shadow.shadowBlurRadius = 1.0;
            (self.labelCell).textColor = [[NSColor blackColor] colorWithAlphaComponent:0.77];
        }
        [shadow set];
        
        (self.labelCell).stringValue = self.toolTip;
        [self.labelCell drawWithFrame:[self labelRectForRect:labelRect] inView:self];
    }
}

#pragma mark Events

- (void)mouseDown:(NSEvent *)theEvent {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    if (self.isHidden) {
        return;
    }
    
//    self.isSelected = YES;
    self.image = [NSImage imageNamed:[self.imageName stringByAppendingString:@"-active"]];
    
    [self display];

    if (actionCallback) {
        self.actionCallback(self);
    }
    
    [super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    if (self.isHidden) {
        return;
    }
    
//    self.isSelected = NO;

    [super mouseUp:theEvent];
    
    self.image = [NSImage imageNamed:self.imageName];

    [self setNeedsDisplay:YES];
}

- (void)mouseEntered:(NSEvent *)theEvent {
#ifdef DEBUG_CAVEMAN
    //DebugLog();
#endif
    
    if (self.isHidden) {
        return;
    }
    
    self.image = [NSImage imageNamed:self.imageName];
   
    [super mouseEntered:theEvent];

    [self setNeedsDisplay];
}

- (void)mouseExited:(NSEvent *)theEvent {
#ifdef DEBUG_CAVEMAN
    //DebugLog();
#endif
    
    if (self.isHidden) {
        return;
    }
    
    [super mouseExited:theEvent];
    
    self.image = nil;
    
    [self setNeedsDisplay];
}

@end
