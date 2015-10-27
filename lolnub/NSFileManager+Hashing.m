//
//  NSFileManager+Hashing.m
//  lolnub
//
//  Created by Anonymous on 1/16/13.
//  Copyright 2014 lolnub.com developers All rights reserved.
//

#import "NSFileManager+Hashing.h"

@implementation NSFileManager (Hashing)

- (NSString *)hashForString:(NSString *)string {
    CC_SHA1_CTX sc;
    
    CC_SHA1_Init(&sc);
    
    CC_SHA1_Update(&sc, string.UTF8String, (unsigned int)string.length);
    
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
	
	CC_SHA1_Final(digest, &sc);
	
	NSMutableString	*output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
	
	int i = 0;
	
    for (i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
	}
	
    return output;
}

- (NSString *)hashOfFileAtPath:(NSString *)absolutePath {
	// as seen on the openssl docs website
	int error = 0;
	unsigned char buffer[8192];
	FILE *file = nil;
	CC_SHA1_CTX sc;
	    
	file = fopen(absolutePath.UTF8String, "rb");
	
	if (!file) {
		return nil;
	}
	
	CC_SHA1_Init(&sc);
	
	size_t length;

	while (true) {		
		length = fread(buffer, 1, sizeof(buffer), file);
		
		if (!length) {
			break;
		}

		CC_SHA1_Update(&sc, buffer, (unsigned int)length);
	}
	
	error = ferror(file);
	fclose(file);
	
	if (error) {
		return nil;
	}
	
	unsigned char digest[CC_SHA1_DIGEST_LENGTH];
	
	CC_SHA1_Final(digest, &sc);
	
	NSMutableString	*output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
	
	int i = 0;
	
    for (i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
	}
	
    return output;
}

@end