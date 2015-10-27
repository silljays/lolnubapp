//
//  BucketWindow.m
//  lolnub
//
//  Created by Anonymous on 2/21/13.
//  Copyright 2014 lolnub.com developers All rights reserved.
//

#import "NubBrandWindow.h"

@implementation NubBrandWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {	
	self = [super initWithContentRect:contentRect styleMask:(NSBorderlessWindowMask | NSResizableWindowMask) backing:bufferingType defer:flag];
    
    if (self) {
        self.backgroundColor = [NSColor clearColor];
        self.alphaValue = 0.986;
        
        [self setHasShadow:YES];
        [self setMovableByWindowBackground:YES];
    }
    
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)isOpaque {
    return NO;
}

- (NSWindowSharingType)sharingType {
    return NSWindowSharingNone;
}

- (IBAction)performMiniaturize:(id)sender {
    [(NubWindowController *)self.delegate performMiniaturize:sender];
}

- (void)shake {
	NSRect startFrame = self.frame;
    
	// shake left
	NSMutableDictionary *leftAnimation = [NSMutableDictionary dictionary];
    
	leftAnimation[NSViewAnimationTargetKey] = self;
	leftAnimation[NSViewAnimationEndFrameKey] = [NSValue valueWithRect:NSMakeRect(startFrame.origin.x - 8, startFrame.origin.y, startFrame.size.width, startFrame.size.height)];
	
	// shake right
	NSMutableDictionary *rightAnimation = [NSMutableDictionary dictionary];
	
	rightAnimation[NSViewAnimationTargetKey] = self;
	rightAnimation[NSViewAnimationEndFrameKey] = [NSValue valueWithRect:NSMakeRect(startFrame.origin.x + 8, startFrame.origin.y, startFrame.size.width, startFrame.size.height)];
	
	// back to center
	NSMutableDictionary *centerAnimation = [NSMutableDictionary dictionary];
	
	centerAnimation[NSViewAnimationTargetKey] = self;
	centerAnimation[NSViewAnimationEndFrameKey] = [NSValue valueWithRect:NSMakeRect(startFrame.origin.x, startFrame.origin.y, startFrame.size.width, startFrame.size.height)];
	
	// start the animation
	NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:@[leftAnimation, rightAnimation, centerAnimation]];
	
	animation.frameRate = 15.0;
	animation.duration = 0.10;
	animation.animationCurve = NSAnimationLinear;
	
	[animation startAnimation];
}

@end
