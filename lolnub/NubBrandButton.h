//
//  NubImageLabelButton.h
//  lolnub
//
//  Created by lolnub.com developers on 10/13/13.
//  Copyright (c) 2014 lolnub.com developers All rights reserved.
//

#import <AppKit/AppKit.h>
#import "NubBrandView.h"

@interface NubBrandButton : NSControl

@property BOOL isSelected;

@property (strong, nonatomic)       NSImage             *image;
@property (strong, nonatomic)       NSString            *imageName;
@property (strong)                  NSImageCell         *imageCell;
@property (strong, nonatomic)       NSString            *label;
@property (strong)                  NSTextFieldCell     *labelCell;

@property (copy, nonatomic)         void                (^actionCallback)(id sender);
@property (assign)                  NSTrackingRectTag   trackingRectTag;

@property (assign)                  BOOL                isSpecial;

- (NSColor *)gradientStartColor;
- (NSColor *)gradientStopColor;

- (NSColor *)labelColor;
- (NSFont *)labelFont;

- (CGFloat)gradientAngle;
- (NSRect)gradientRect;

- (NSBezierPath *)clipPath;

- (BOOL)wantsDefaultDrawRect;
- (void)drawBackgroundInRect:(NSRect)backgroundRect;
- (void)drawImageInRect:(NSRect)labelRect;
- (void)drawLabelInRect:(NSRect)labelRect;

@end
