//
//  NSFileManager+Hashing.h
//  lolnub
//
//  Created by Anonymous on 1/16/13.
//  Copyright 2014 lolnub.com developers All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CommonCrypto/CommonDigest.h>

@interface NSFileManager (Hashing)

// return the hash of the absolutePath string itself
- (NSString *)hashForString:(NSString *)string;

// return the hash of a file located at absolutePath
- (NSString *)hashOfFileAtPath:(NSString *)absolutePath;

@end
