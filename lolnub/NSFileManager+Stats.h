//
//  NSFileManager+Stats.h
//  lolnub
//
//  Created by Anonymous on 1/13/13.
//  Copyright 2014 lolnub.com developers All rights reserved.
//

#import <Cocoa/Cocoa.h>

// generic error
#define FILE_SYSTEM_ERROR -1

@interface NSFileManager (Stats)

// return the number of actual bytes used by the item at absolutePath
- (unsigned long long)byteCountOfItemAtPath:(NSString *)absolutePath;

// return various stats about the file system that contains absolutePath
- (unsigned long long)freeByteCountOfFileSystemContainingPath:(NSString *)absolutePath;
- (unsigned long long)usedByteCountOfFileSystemContainingPath:(NSString *)absolutePath;

@end
