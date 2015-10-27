//
//  NSFileManager+Stats.m
//  lolnub
//
//  Created by Anonymous on 1/13/13.
//  Copyright 2014 lolnub.com developers All rights reserved.
//

#import "NSFileManager+Stats.h"

@implementation NSFileManager (Stats)

- (unsigned long long)byteCountOfItemAtPath:(NSString *)absolutePath {	
	NSError *error = nil;
	
	NSDictionary *fileAttributes = [self attributesOfItemAtPath:absolutePath error:&error];
	
	if (error) {
        DebugLog();
		NSLog(@"***error: %@", error);
		return FILE_SYSTEM_ERROR;
	}
	
	return [fileAttributes[NSFileSize] longLongValue];
}

- (unsigned long long)freeByteCountOfFileSystemContainingPath:(NSString *)absolutePath {
	NSError *error = nil;
	
	NSDictionary *fileSystemAttributes = [self attributesOfFileSystemForPath:absolutePath error:&error];
	
	if (error) {
        DebugLog();
		NSLog(@"***error: %@", error);
        
		return FILE_SYSTEM_ERROR; 
	}
		
	return [fileSystemAttributes[NSFileSystemFreeSize] longLongValue];
}

- (unsigned long long)usedByteCountOfFileSystemContainingPath:(NSString *)absolutePath {
	NSError *error = nil;
	
	NSDictionary *fileSystemAttributes = [self attributesOfFileSystemForPath:absolutePath error:&error];
	
	if (error) {
        DebugLog();
		NSLog(@"***error: %@", error);
        
		return FILE_SYSTEM_ERROR; 
	}
    
    unsigned long long totalBytes   = [fileSystemAttributes[NSFileSystemSize] longLongValue];
    unsigned long long freeBytes    = [fileSystemAttributes[NSFileSystemFreeSize] longLongValue];

	return totalBytes - freeBytes;
}

@end
