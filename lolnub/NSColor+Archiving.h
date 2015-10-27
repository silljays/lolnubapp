//
//  NSColor+Archiving.h
//  lolnub
//
//  Created by Anonymous on 11/13/13.
//  Copyright 2014 lolnub.com developers All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (Archiving)

+ (NSColor *)colorFromArray:(NSArray *)colorArray;

- (NSArray *)colorArray;

@end
