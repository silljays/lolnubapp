//
//  NubSpecialView.h
//  lolnub
//
//  Created by Anonymous on 10/18/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <QTKit/QTKit.h>

@interface NubSpecialView : IKImageView

@property                       BOOL                dragging;
@property                       NSPoint             lastDragPoint;
@property                       NSRect              dragRect;
@property                       NSPoint             lastMouseDownPoint;
@property                       NSTimeInterval      lastMouseDownTime;

@property (strong)              IBOutlet NSMenu     *itemContextMenu;

- (void)setImageFromItem:(NubItem *)newItem;

- (void)setImageFromImage:(NSImage *)newImage;

@end
