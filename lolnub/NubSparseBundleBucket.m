//
//  NubBucket.m
//  lolnub
//
//  Created by Anonymous on 6/13/13.
//  Copyright 2014 lolnub.com developers All rights reserved.
//

#import "NubSparseBundleBucket.h"

#define STORAGE_NAME @"storage.sparsebundle"

static NubSparseBundleBucket *instance = nil;

@interface NubSparseBundleBucket (Private)

- (int)x_forceUnmountBucket:(NSString *)mountPath;

- (NSString *)x_createUniqueTemporaryDirectory;

@end

@implementation NubSparseBundleBucket

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

	// save the cwd to return to it later
	NSString *workingDirectory = self.currentDirectoryPath;
	
	// grab the directories for the Nub and the Nub name
	NSString *bucketDirectoryPath = absolutePath.stringByDeletingLastPathComponent;
	NSString *bucketName = absolutePath.lastPathComponent;
	
	// add the file extension if necessary
	if (![bucketName hasSuffix:DOCUMENT_EXTENSION]) {
		bucketName = [bucketName stringByAppendingPathExtension:DOCUMENT_EXTENSION];
	}

	// copy the template Nub to the new location
	NSString *templateBucketPath = [[NSBundle mainBundle] pathForResource:@"template" ofType:DOCUMENT_EXTENSION];
	
	// create the new fully qualified Nub path
	NSString *bucketPath = [bucketDirectoryPath stringByAppendingPathComponent:bucketName];
	
	// copy and rename the template Nub into the new location
	[self copyItemAtPath:templateBucketPath toPath:bucketPath error:&error];
	
	if (error) {
        DebugLog();
		NSLog(@"***error: %@", error);

		return nil;
	}

	// now we create the encrypted disk image inside the template Nub bucketage
	NSString *sparseBundlePath = [[bucketPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Storage"];
	
	sysError = chdir(sparseBundlePath.UTF8String);
	
	if (sysError) {
		NSLog(@"***sysError: %d", sysError);
		
		return nil;
	}
	
	NSString *command = [NSString stringWithFormat:
                         @"printf '%s' | hdiutil create -stdinpass -megabytes '%d' -encryption '%@' -type SPARSEBUNDLE -nospotlight -fs 'Journaled HFS+' -volname '%@' '%@'",
                         newPasscode.UTF8String,
                         mbSize,
                         cryptType,
                         bucketName,
                         @"storage"];
        
	sysError = system(command.UTF8String);

	if (sysError) {
		NSLog(@"***sysError: %d", sysError);
		
		return nil;
	}
	
	// change back to the previous path
	sysError = chdir(workingDirectory.UTF8String);
	
	if (sysError) {
		NSLog(@"***sysError: %d", sysError);

		return nil;
	}

	return bucketPath;
}

- (NSString *)openBucketWithPasscode:(NSString *)passcode atPath:(NSString *)absolutePath {
    //hdiutil info | grep .nub | grep \/dev | awk '{ print $3 }' | xargs hdiutil unmount -force
	NSString *sparseBundlePath = [[[absolutePath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Storage"] stringByAppendingPathComponent:STORAGE_NAME];
	
	// where the Nub should be mounted
	NSString *bucketMountPath = [self.x_createUniqueTemporaryDirectory stringByAppendingPathComponent:absolutePath.lastPathComponent];
    
    // try to mount the Nub
	NSString *mountCommand = [NSString stringWithFormat:@"printf '%s' | hdiutil attach -mountpoint '%@' -stdinpass -nobrowse  '%@'", passcode.UTF8String, bucketMountPath, sparseBundlePath];
	
	if (system(mountCommand.UTF8String)) {		
		return nil;
	}

    // todo: error check the Nub is mounted
    
    // enforce strict permissions on the Nub
    NSString *permissionCommand = [NSString stringWithFormat:@"chmod 700 '%@'", bucketMountPath];

    if (system(permissionCommand.UTF8String)) {
        return nil;
    }
    
	// alert others that a Nub has been mounted
	[[NSNotificationCenter defaultCenter] postNotificationName:NubBucketDidMountBucketNotification object:bucketMountPath];
	
	return bucketMountPath;
}

- (BOOL)changeBucketPasscode:(NSString *)newPasscode currentPasscode:(NSString *)currentPasscode atPath:(NSString *)absolutePath {
	NSString *sparseBundlePath = [[[absolutePath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Storage"] stringByAppendingPathComponent:STORAGE_NAME];

	NSString *command = [NSString stringWithFormat:@"printf '%s\\0%s\\0' | hdiutil chpass -oldstdinpass -newstdinpass '%s'", currentPasscode.UTF8String, newPasscode.UTF8String, sparseBundlePath.UTF8String];
	
	int sysError = 0;
	
	sysError = system(command.UTF8String);
	
	return (sysError == 0);
}

- (BOOL)changeBucketByteSize:(int)mbSize currentPasscode:(NSString *)currentPasscode atPath:(NSString *)absolutePath {
    // resize the image
    NSString *command = [NSString stringWithFormat:@"printf '%s\\0' | hdiutil resize -megabytes '%d' -stdinpass -nofinalgap '%s'",
                         [currentPasscode UTF8String],
                         mbSize,
                         [absolutePath UTF8String]];
    
    int sysError = 0;
    
    sysError = system([command UTF8String]);
    
    if (sysError) {
        return NO;
    }
    
    // mount the volume
    command = [NSString stringWithFormat:@"printf '%s' | hdiutil attach -stdinpass -nobrowse '%@'", [currentPasscode UTF8String], absolutePath];
    
    sysError = system([command UTF8String]);
    
    if (sysError) {
        return NO;
    }
    
    // resize the volume
    NSString *mountPath = [@"/Volumes" stringByAppendingPathComponent:[absolutePath lastPathComponent]];
    
    command = [NSString stringWithFormat:@"diskutil resizeVolume '%@' %dM",
               mountPath,
               mbSize];
    
    sysError = system([command UTF8String]);
    
    if (sysError) {
        return NO;
    }
    
    // ensure the stash is unmounted
    [self x_forceUnmountBucket:mountPath];
    
    return YES;
}

- (BOOL)closeBucketAtMountPath:(NSString *)mountPath {
	NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
	
	// notify others that the Nub is *going* down
	[noteCenter postNotificationName:NubBucketWillUnmountBucketNotification object:mountPath];
	
	// todo: add force as an optional parameter
	if ([self x_forceUnmountBucket:mountPath]) {
        return NO;
    }
    else {
        // notify others that the Nub *is* down
        [noteCenter postNotificationName:NubBucketDidUnmountBucketNotification object:mountPath];
    }

	return YES;
}

@end

@implementation NubSparseBundleBucket (Private)

- (int)x_forceUnmountBucket:(NSString *)mountPath {
	// eject whatever Nub we're working with
	return system([NSString stringWithFormat:@"hdiutil detach -force '%@'", mountPath].UTF8String);
}

- (NSString *)x_createUniqueTemporaryDirectory {
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
    
    NSError *error = nil;
    
    [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:NULL error:&error];
    
	if (error) {
        DebugLog();
		NSLog(@"***error: %@", error);
        
		return nil;
	}
    
    return tempPath;
}

@end

