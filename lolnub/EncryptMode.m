//
//  EncryptMode.m
//  lolnub
//
//  Created by Anonymous on 8/1/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "EncryptMode.h"


@interface EncryptMode ()

- (void)x_clearFields;

@end

@implementation EncryptMode

- (BOOL)isAdminMode {
    return YES;
}

- (BOOL)isSwitchable {
    return NO;
}

- (void)afterAwakeFromNib {
    self.encryptionSelection = NO;
}

- (void)sleepToBackground {
    [self x_clearFields];
    
    [super sleepToBackground];
}

+ (Nub *)quickCreateNub:(NSString *)typeString {
    NSError *error = nil;
    
    Nub *nub = [[AppController sharedAppController] openUntitledDocumentAndDisplay:YES error:&error];
    
    // From `myeyesareblind` + `Jeff B`: http://stackoverflow.com/questions/2633801/generate-a-random-alphanumeric-string-in-cocoa
    NSString *randomString = [[NSProcessInfo processInfo] globallyUniqueString].lowercaseString;
    
    // create the nub/bucket
    NSString *tmpBucketPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:randomString];
    
    // check that a path has been selected and it exists
    NSString *containingDirectory = tmpBucketPath.stringByDeletingLastPathComponent;
    
    BOOL isDirectory    = NO;
    BOOL fileExists     = NO;
    
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:containingDirectory isDirectory:&isDirectory];
    
    if (!fileExists || !isDirectory) {
        [[AppController sharedAppController]
         alert: @"Sorry but the place you selected will not work."
         info: @"Pick a different disk or network and try again."
         style: NSInformationalAlertStyle];
        
        return nil;
    }
    
    // check if the file already exists
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:tmpBucketPath isDirectory:&isDirectory];
    
    if (fileExists) {
        [[AppController sharedAppController]
         alert: @"Sorry but to help be safe, we don't allow saving over other documents."
         info:  @"Pick a different name and try again or contact support for more."
         style: NSCriticalAlertStyle];
        
        return nil;
    }
    
    // Actual Creation
    NSString *documentBucketPath = nil;
    
    if([typeString isEqualToString:@"passcode"]) {
        documentBucketPath = [[NubBucket encryptManager]
                              createBucketWithMBSize:DEFAULT_BUCKET_MB_SIZE
                              encryptionType:DEFAULT_ENCRYPTION_TYPE
                              newPasscode:DEFAULT_PASSCODE
                              atPath:tmpBucketPath];
        
        [@"passcode is `lolnub` and you should change it soon" writeToFile:[documentBucketPath stringByAppendingPathComponent:BUCKET_HINT_FILENAME] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        
    }
    else {
        documentBucketPath = [[NubBucket folderManager]
                              createBucketWithMBSize:DEFAULT_BUCKET_MB_SIZE
                              encryptionType:nil
                              newPasscode:nil
                              atPath:tmpBucketPath];
        
        [@"there is NO passcode because this is a Public Folder nub" writeToFile:[documentBucketPath stringByAppendingPathComponent:BUCKET_HINT_FILENAME] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
    
    if (!documentBucketPath) {
        [[AppController sharedAppController]
         alert: @"Sorry but there was an error creating the Nub."
         info:  @"Check your stuff and try again or contact support for more."
         style: NSCriticalAlertStyle];
        
        return nil;
    }
    
    // set the Nub up to the new mounted Nub path
    nub.bucketPath = documentBucketPath;
    
    return nub;
}

- (IBAction)encryptBucket:(id)sender {
    NSString *tmpBucketPasscode          = (self.bucketPasscode).stringValue;
    NSString *tmpBucketVerifyPasscode    = (self.bucketVerifyPasscode).stringValue;
    NSString *tmpBucketPasscodeHint      = (self.bucketPasscodeHint).stringValue;
    
    if (self.encryptionSelection) {
        // check for empty passcode and verify fields
        if ([tmpBucketPasscode isEqualToString:@""] || [tmpBucketVerifyPasscode isEqualToString:@""]) {
            NSAlert *alert = [[NSAlert alloc] init];
            
            [alert addButtonWithTitle:@"Set a Passcode"];
            [alert addButtonWithTitle:@"Ignore Passcode"];
            alert.messageText = @"You have not entered a Passcode.";
            alert.informativeText = @"If you do NOT use a passcode, anyone will be able to view your files.";
            alert.alertStyle = NSWarningAlertStyle;
            
            if ([alert runModal] == NSAlertFirstButtonReturn) {
                return;
            }
        }
        
        // check that the passcode and verify strings are equal
        if (![tmpBucketPasscode isEqualToString:tmpBucketVerifyPasscode]) {
            [[AppController sharedAppController]
             alert: @"Sorry but the Passcode fields kind of need to match."
             info:  @"Check that your stuff matches and try again or contact support for more."
             style: NSCriticalAlertStyle];
            
            return;
        }
        
        // check for an empty hint and ask wether to proceed
        if ([tmpBucketPasscodeHint isEqualToString:@""]) {
            NSAlert *alert = [[NSAlert alloc] init];
            
            [alert addButtonWithTitle:@"Set a Hint"];
            [alert addButtonWithTitle:@"Ignore Hint"];
            alert.messageText = @"You have not entered a hint.";
            alert.informativeText = @"Most people find hints helpful, but they are optional.";
            alert.alertStyle = NSWarningAlertStyle;
            
            // first button is Set a Hint specified above
            if ([alert runModal] == NSAlertFirstButtonReturn) {
                return;
            }
        }
    }
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    [panel setCanCreateDirectories:YES];
    panel.prompt = @"Create Nub";
    panel.nameFieldStringValue = @"Untitled.nub";
    
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (!result == NSFileHandlingPanelOKButton) {
            return;
        }
        
        NSString *tmpBucketPath = panel.URL.path;
        
        // check that a path has been selected and it exists
        BOOL isDirectory    = NO;
        BOOL fileExists     = NO;
        
        NSString *containingDirectory = tmpBucketPath.stringByDeletingLastPathComponent;
        
        fileExists = [[NSFileManager defaultManager] fileExistsAtPath:containingDirectory isDirectory:&isDirectory];
        
        if (!fileExists || !isDirectory) {
            [[AppController sharedAppController]
             alert: @"Sorry but the place you selected will not work and we don't really know why."
             info:  @"Check your stuff, pick a different spot, try again later, and/or contact support."
             style: NSInformationalAlertStyle];
            
            return;
        }
        
        // check if the file already exists
        fileExists = [[NSFileManager defaultManager] fileExistsAtPath:tmpBucketPath isDirectory:&isDirectory];
        
        if (fileExists) {
            NSAlert *alert = [[NSAlert alloc] init];
            
            [alert addButtonWithTitle:@"Quit"];
            alert.messageText = @"Sorry but to be safe we don't allow saving over other stuff.";
            alert.informativeText = @"Pick a different name and try again or contact support for more.";
            alert.alertStyle = NSCriticalAlertStyle;
            
            [alert runModal];
            
            return;
        }
        
        NSString *documentBucketPath = nil;
        
        // check that the agreement/warning was accepted
        if (self.encryptionSelection) {
            documentBucketPath = [[NubBucket encryptManager]
                                    createBucketWithMBSize:DEFAULT_BUCKET_MB_SIZE
                                            encryptionType:DEFAULT_ENCRYPTION_TYPE
                                               newPasscode:tmpBucketPasscode
                                                    atPath:tmpBucketPath];
        }
        else {
            documentBucketPath = [[NubBucket folderManager]
                                    createBucketWithMBSize:DEFAULT_BUCKET_MB_SIZE
                                            encryptionType:DEFAULT_ENCRYPTION_TYPE
                                               newPasscode:tmpBucketPasscode
                                                    atPath:tmpBucketPath];
        }
        
        if (!documentBucketPath) {
            NSAlert *alert = [[NSAlert alloc] init];
            
            [alert addButtonWithTitle:@"Quit"];
            alert.messageText = @"Sorry but there was an error creating the Nub.";
            alert.informativeText = @"Check your stuff and try again or contact support for more.";
            alert.alertStyle = NSCriticalAlertStyle;
            
            [alert runModal];
        }
        else {
            [tmpBucketPasscodeHint writeToFile:[documentBucketPath stringByAppendingPathComponent:BUCKET_HINT_FILENAME] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
            
            [self x_clearFields];
            
            // set the Nub up to the new mounted Nub path
            self.delegate.bucketPath = documentBucketPath;
        }
    }];
}

- (void)x_clearFields {
    self.bucketPasscode.stringValue          = @"";
    self.bucketVerifyPasscode.stringValue    = @"";
    self.bucketPasscodeHint.stringValue      = @"";
    self.encryptionSelection                 = NO;
}

@end