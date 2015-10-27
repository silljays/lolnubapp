//
//  NubFolderBucket.m
//  lolnub
//
//  Created by Anonymous on 5/12/14.
//  Copyright (c) 2015 lolnub.com. All rights reserved.
//

#import "NubFolderBucket.h"

#define STORAGE_NAME @"storage.folder"

static NubFolderBucket *instance = nil;

@implementation NubFolderBucket

+ (id)defaultManager {
    if (!instance) {
		instance = [[self alloc] init];
    }
	
    return instance;
}

- (void)dealloc {
    instance = nil;
}

- (NSString *)createBucketWithMBSize:(int)mbSize encryptionType:(NSString *)cryptType newPasscode:(NSString *)newPasscode atPath:(NSString *)absolutePath {
	NSError *error = nil;
	int sysError = 0;

	// grab the directories for the Nub and the Nub name
	NSString *bucketDirectoryPath = absolutePath.stringByDeletingLastPathComponent;
	NSString *bucketName = absolutePath.lastPathComponent;
	
	// add the file extension if necessary
	if (![bucketName hasSuffix:DOCUMENT_EXTENSION]) {
		bucketName = [bucketName stringByAppendingPathExtension:DOCUMENT_EXTENSION];
	}

	// create the new fully qualified Nub path
	NSString *bucketPath = [bucketDirectoryPath stringByAppendingPathComponent:bucketName];
	
	// copy and rename the template Nub into the new location
	[self createDirectoryAtPath:bucketPath withIntermediateDirectories:YES attributes:NULL error:NULL];
    
	if (error) {
        DebugLog();
		NSLog(@"***error: %@", error);
        
		return nil;
	}

	// change back to the previous path
	sysError = chdir(bucketPath.UTF8String);
	
	if (sysError) {
		NSLog(@"***sysError: %d", sysError);
        
		return nil;
	}
    
	return bucketPath;
}

- (NSString *)openBucketWithPasscode:(NSString *)passcode atPath:(NSString *)absolutePath {
    //hdiutil info | grep .nub | grep \/dev | awk '{ print $3 }' | xargs hdiutil unmount -force
	NSString *bucketPath = absolutePath;

	// alert others that a Nub has been mounted
	[[NSNotificationCenter defaultCenter] postNotificationName:NubBucketDidMountBucketNotification object:bucketPath];
	
	return bucketPath;
}

- (BOOL)changeBucketPasscode:(NSString *)newPasscode currentPasscode:(NSString *)currentPasscode atPath:(NSString *)absolutePath {
    return YES;
}

- (BOOL)changeBucketByteSize:(long long)byteSize currentPasscode:(NSString *)currentPasscode atPath:(NSString *)absolutePath {
	return YES;
}

- (BOOL)closeBucketAtMountPath:(NSString *)mountPath {
    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
	
	// notify others that the Nub is *going* down
	[noteCenter postNotificationName:NubBucketWillUnmountBucketNotification object:mountPath];
    [noteCenter postNotificationName:NubBucketDidUnmountBucketNotification object:mountPath];
    
	return YES;
}

@end

