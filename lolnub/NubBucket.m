//
//  NubBucket.m
//  lolnub
//
//  Created by Anonymous on 11/13/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//


#import "NubBucket.h"
#import "NubFolderBucket.h"
#import "NubSparseBundleBucket.h"


NSString *const NubBucketDidMountBucketNotification        = @"NubBucketDidMountBucketNotification";
NSString *const NubBucketWillUnmountBucketNotification     = @"NubBucketWillUnmountBucketNotification";
NSString *const NubBucketDidUnmountBucketNotification      = @"NubBucketDidUnmountBucketNotification";


@implementation NubBucket

+ (id)defaultManager {
    return [[NubBucket alloc] init];
}

+ (id)folderManager {
    return [NubFolderBucket defaultManager];
}

+ (id)encryptManager {
    return [NubSparseBundleBucket defaultManager];
}

- (NSString *)createBucketWithMBSize:(int)mbSize encryptionType:(NSString *)cryptType newPasscode:(NSString *)newPasscode atPath:(NSString *)absolutePath {
	return nil;
}

- (NSString *)openBucketWithPasscode:(NSString *)currentPasscode atPath:(NSString *)absolutePath {
    // try to look for and decrypt a nub first, if it fails, try the folder, then nil.
    NSString *storagePath = [[absolutePath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Storage"];
    
    if ([self fileExistsAtPath:storagePath]) {
        return [[NubBucket encryptManager] openBucketWithPasscode:currentPasscode atPath:absolutePath];
    }
    else {
        return [[NubBucket folderManager] openBucketWithPasscode:currentPasscode atPath:absolutePath];
    }
    
	return nil;
}

- (BOOL)changeBucketPasscode:(NSString *)newPasscode currentPasscode:(NSString *)currentPasscode atPath:(NSString *)absolutePath {
	return NO;
}

- (BOOL)changeBucketByteSize:(long long)megabyteSize currentPasscode:(NSString *)currentPasscode atPath:(NSString *)absolutePath {
	return NO;
}

- (BOOL)closeBucketAtMountPath:(NSString *)mountPath {
    
    if ([mountPath hasPrefix:@"/var/folders"]) {
        return [[NubBucket encryptManager] closeBucketAtMountPath:mountPath];
    }
    else {
        return [[NubBucket folderManager] closeBucketAtMountPath:mountPath];
    }
    
	return YES;
}

@end
