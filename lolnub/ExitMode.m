//
//  ExitMode.m
//  lolnub
//
//  Created by Anonymous on 11/5/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "ExitMode.h"

#define STATUS_SECURE_STRING        @"Secure."
#define STATUS_READABLE_STRING      @"Closing..."

@implementation ExitMode

- (BOOL)isAdminMode {
    return YES;
}

- (void)reloadData {
    [self x_updateSecureStatus];
}

- (void)awakeFromNib {
    [self.spinnerView startAnimation:self];
        
    [self.view display];

    // close the media
    for (NubMedia *mediaController in self.delegate.mediaControllers) {
        [mediaController close];
    }
    
    [self.view setNeedsDisplay:YES];
}

- (void)afterAwakeFromNib {
    NSString *bucketPath = self.delegate.bucketManager.rootPath;
    
    if (bucketPath) {
        // save prefs and such
        [self.delegate save:self];
        
        // add our observer here which will be called from unmountBucket: below on succesful unmounting
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(x_close)
                                                     name:NubBucketDidUnmountBucketNotification
                                                   object:bucketPath];
        
        [[NubBucket defaultManager] closeBucketAtMountPath:bucketPath];        
    }
    else {
        [self x_close];
    }
}

- (void)fullyAwake {
    [self x_updateSecureStatus];
    
    [super fullyAwake];
}

- (void)dealloc {
    [self.spinnerView stopAnimation:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)x_close {
    [self.nub save:self];
    
    [(self.view).superview display];

    @try {
        [self.delegate.window close];
    }
    @catch (NSException *exception) {        
    }
}

- (BOOL)isSwitchable {
    return NO;
}

- (void)x_updateSecureStatus {
    NSString *status = nil;
    
    if (self.isReadable) {
        status = STATUS_READABLE_STRING;
    }
    else {
        status = STATUS_SECURE_STRING;
    }
    
    self.secureStatus.stringValue = status;
    
    [self.view setNeedsDisplay:YES];
}

@end
