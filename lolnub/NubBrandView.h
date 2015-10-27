//
//  NubBrandView.h
//  lolnub
//
//  Created by Anonymous on 8/2/13.
//  Copyright (c) 2014 lolnub.com developers All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NubBrandView : NSView

@property (strong) NSColor  *brandColor;
@property (strong, nonatomic) NSColor *gradientStartColor;
@property (strong, nonatomic) NSColor *gradientStopColor;

- (CGFloat)gradientAngle;
- (NSRect)gradientRect;

- (NSBezierPath *)clipPath;

- (BOOL)wantsDefaultDrawRect;

@end
