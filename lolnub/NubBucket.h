//
//  NubBucket.h
//  lolnub
//
//  Created by Anonymous on 11/13/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//
//  #todo: formalize the api/protocol and class cluster support.
//  #todo: add REST buckets
//  #todo: add open source crypt support (true, pgp, etc)

#import <Foundation/Foundation.h>

extern NSString *const NubBucketDidMountBucketNotification;
extern NSString *const NubBucketWillUnmountBucketNotification;
extern NSString *const NubBucketDidUnmountBucketNotification;

@interface NubBucket : NSFileManager

+ (id)defaultManager;
+ (id)folderManager;
+ (id)encryptManager;

#pragma mark CoreAPI

// create a new Nub with options and return the path to the Nub
- (NSString *)createBucketWithMBSize:(int)mbSize encryptionType:(NSString *)cryptType newPasscode:(NSString *)newPasscode atPath:(NSString *)absolutePath;

// mount an existing Nub at absolutePath and return the bucket's mounted path (e.g. /tmp/.Example.nub)
- (NSString *)openBucketWithPasscode:(NSString *)currentPasscode atPath:(NSString *)absolutePath;

// change the passcode for the given storage
- (BOOL)changeBucketPasscode:(NSString *)newPasscode currentPasscode:(NSString *)currentPasscode atPath:(NSString *)absolutePath;

// change the size in bytes of the given storage
- (BOOL)changeBucketByteSize:(long long)byteSize currentPasscode:(NSString *)currentPasscode atPath:(NSString *)absolutePath;

// unmount the storage
- (BOOL)closeBucketAtMountPath:(NSString *)mountPath;

@end
