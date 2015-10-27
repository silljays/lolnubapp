//
//  NSString+ByteCount.m
//  lolnub
//
//  Created by Anonymous on 7/15/13.
//  Copyright 2014 lolnub.com developers All rights reserved.
//

#import "NSString+ByteCount.h"

@implementation NSString (ByteCount)

+ (NSString *)stringFromByteCount:(NSInteger)byteCount {
	NSString *formatString = nil;
	
	if (byteCount < MEGABYTE) {
		formatString = [NSString stringWithFormat:@"%.0f KB", (double)byteCount / KILOBYTE];
	}
	else if (byteCount < GIGABYTE) {
		formatString = [NSString stringWithFormat:@"%.1f MB", (double)byteCount / MEGABYTE];
	}
	else if (byteCount < TERABYTE) {
		formatString = [NSString stringWithFormat:@"%.1f GB", (double)byteCount / GIGABYTE];
	}
	else {
		formatString = [NSString stringWithFormat:@"%.1f TB", (double)byteCount / TERABYTE];
	}
	
	// remove any blank decimal spots
	return [formatString stringByReplacingOccurrencesOfString:@".0" withString:@""];
}

@end
