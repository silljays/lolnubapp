//
//  DecryptMode.m
//  lolnub
//
//  Created by Anonymous on 8/1/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "DecryptMode.h"


@interface DecryptMode ()

- (void)x_clearFields;

@end


@implementation DecryptMode

@synthesize bucketPasscode;
@synthesize bucketHint;

- (BOOL)isAdminMode {
    return YES;
}

- (BOOL)isSwitchable {
    return NO;
}

- (void)afterAwakeFromNib {
    // close the Nub when we are brought to the front
    if (self.delegate) {
        [[NubBucket defaultManager] closeBucketAtMountPath:self.delegate.bucketPath];
    }

    NSString *bucketDocumentPath = self.delegate.documentPath;

    self.bucketName.stringValue = bucketDocumentPath.lastPathComponent;
    self.bucketHint.stringValue = [NSString stringWithContentsOfFile:[bucketDocumentPath stringByAppendingPathComponent:BUCKET_HINT_FILENAME] encoding:NSUTF8StringEncoding error:NULL];
}

- (void)sleepToBackground {
    [self x_clearFields];
    
    [super sleepToBackground];
}

#pragma mark Actions

- (IBAction)decryptBucket:(id)sender {
    // check and execute any callback
    if (self.actionCallback) {
        self.actionCallback(self);
        
        self.actionCallback = nil;
    }

    // try to mount the Nub with our given passcode and path
    NSString *mountedBucketPath = [[NubBucket defaultManager] openBucketWithPasscode:self.bucketPasscode.stringValue atPath:self.delegate.documentPath];
    
    // clear the passcode regardless of the mount attempt, or its correctness
    [self x_clearFields];
    
    // mountedBucketPath will be nil if the passcode was incorrect or the Nub is damaged
    if (!mountedBucketPath || [mountedBucketPath isEqualToString:@""]) {
        [self.delegate.window shake];
        
        NSBeep();
        return;
    }
    
    // set the Nub up to the new mounted Nub path
    self.delegate.bucketPath = mountedBucketPath;
}

#pragma mark Private

- (void)x_clearFields {
    self.bucketPasscode.stringValue = @"";    
}

@end
