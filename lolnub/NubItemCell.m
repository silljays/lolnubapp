//
//  NubItemCell.m
//  HappyHush
//
//  Created by Anonymous on 10/13/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "NubItemCell.h"

#define CELL_PADDING 3.0
#define DELEGATE_FONT_SIZE 15.0
#define SELECTED_PADDING 10.0

@implementation NubItemCell

@synthesize iconCell, labelCell;

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.iconCell = [[NSImageCell alloc] init];
        iconCell.imageAlignment = NSImageAlignCenter;
        iconCell.imageScaling = NSImageScaleProportionallyUpOrDown;
        
        self.labelCell = [[NSTextFieldCell alloc] init];
        labelCell.alignment = NSCenterTextAlignment;
        labelCell.lineBreakMode = NSLineBreakByWordWrapping;
        labelCell.font = [NSFont systemFontOfSize:DELEGATE_FONT_SIZE];
        labelCell.textColor = [[NSColor whiteColor] colorWithAlphaComponent:0.66];
    }
    
    return self;
}

@end
