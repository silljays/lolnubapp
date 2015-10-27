//
//  NSColor+Archiving.m
//  lolnub
//
//  Created by Anonymous on 11/13/13.
//  Copyright 2014 lolnub.com developers All rights reserved.
//

#import "NSColor+Archiving.h"


@implementation NSColor (Archiving)

+ (NSColor *)colorFromArray:(NSArray *)colorArray {    
	if(!colorArray || (colorArray.count < 4)) {
		return nil;
	}
	
	return [NSColor colorWithCalibratedRed:[colorArray[0] floatValue] green:[colorArray[1] floatValue] blue:[colorArray[2] floatValue] alpha:[colorArray[3] floatValue]];
}

- (NSArray *)colorArray {
	NSColor *calibratedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	
	return @[
        @((float)calibratedColor.redComponent),
        @((float)calibratedColor.greenComponent),
        @((float)calibratedColor.blueComponent),
        @((float)calibratedColor.alphaComponent)
    ];
}

@end