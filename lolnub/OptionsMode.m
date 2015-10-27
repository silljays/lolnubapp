//
//  OptionsMode.m
//  lolnub
//
//  Created by Anonymous on 9/19/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "OptionsMode.h"

#define SELF_DESTRUCT_SUFFIX @"!+"

@interface OptionsMode (Private)

- (void)x_clearFields;

@end

@implementation OptionsMode

@synthesize bucketName;
@synthesize bucketPasscode;
@synthesize bucketNewPasscode;
@synthesize bucketNewVerifyPasscode;
@synthesize bucketPasscodeHint;

- (BOOL)isAdminMode {
    return YES;
}

- (BOOL)isSwitchable {
    return NO;
}

- (void)afterAwakeFromNib {
    [self x_clearFields];
}

- (IBAction)cancel:(id)sender {
    [self.delegate setMode:DEFAULT_BUCKET_MODE];
}

- (IBAction)updatePasscode:(id)sender {
	// check for empty passcode and verify fields
	if ([bucketPasscode.stringValue isEqualToString:@""] || [bucketNewPasscode.stringValue isEqualToString:@""] || [bucketNewVerifyPasscode.stringValue isEqualToString:@""]) {
		NSAlert *alert = [[NSAlert alloc] init];

		[alert addButtonWithTitle:@"OK"];
		alert.messageText = @"None of the passcodes can be blank.";
		alert.informativeText = @"Fill them all out or Cancel to continue.";
		alert.alertStyle = NSInformationalAlertStyle;

		[alert runModal];

		return;
	}

	// check that the passcode and verify strings are equal
	if (![bucketNewPasscode.stringValue isEqualToString:bucketNewVerifyPasscode.stringValue]) {
		NSAlert *alert = [[NSAlert alloc] init];

		[alert addButtonWithTitle:@"OK"];
		alert.messageText = @"The New Passcode and Verify fields much match each other.";
		alert.informativeText = @"Make sure the passcodes match.";
		alert.alertStyle = NSInformationalAlertStyle;

		[alert runModal];

		return;
	}

	// check that they are not using the self-destruct activation code in their passcode
	if ([bucketNewPasscode.stringValue hasSuffix:SELF_DESTRUCT_SUFFIX]) {
		NSAlert *alert = [[NSAlert alloc] init];

		[alert addButtonWithTitle:@"OK"];
		alert.messageText = @"The last two letters of the Passcode may not be used.";
		alert.informativeText = @"The \"bangnow\" code is used with panic passcodes to trigger a Dead Man's Switch. See \"Panic Passcodes\" for more.";
		alert.alertStyle = NSInformationalAlertStyle;

		[alert runModal];

		return;
	}

	// check for an empty hint and ask wether to proceed
	if ([bucketPasscodeHint.stringValue isEqualToString:@""]) {
		NSAlert *alert = [[NSAlert alloc] init];

		[alert addButtonWithTitle:@"Set a Hint"];
		[alert addButtonWithTitle:@"Ignore Passcode Hint"];
		alert.messageText = @"You have not entered a passcode hint.";
		alert.informativeText = @"Hints can help you remember the passcode.";
		alert.alertStyle = NSWarningAlertStyle;

		// first button is Set a Hint specified above
		if ([alert runModal] == NSAlertFirstButtonReturn) {
			return;
		}
	}
    
    NSString *bucketDocumentPath  = self.delegate.documentPath;

    // set the master passcode hint
    [bucketPasscodeHint.stringValue writeToFile:[bucketDocumentPath stringByAppendingPathComponent:BUCKET_HINT_FILENAME] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
    [self.delegate close:self];
    
	// call out to NubBucket with a change passcode method
	if (![[NubBucket defaultManager] changeBucketPasscode:bucketNewPasscode.stringValue currentPasscode:bucketPasscode.stringValue atPath:bucketDocumentPath]) {
		NSAlert *alert = [[NSAlert alloc] init];

		[alert addButtonWithTitle:@"OK"];
		alert.messageText = @"Unable to change passcodes.";
		alert.informativeText = @"Please try again or contact support for more.";
		alert.alertStyle = NSCriticalAlertStyle;
		
		[alert runModal];
		
		return;
	}

    [self x_clearFields];
    
    [[NSWorkspace sharedWorkspace] openFile:bucketDocumentPath];
}

@end

@implementation OptionsMode (Private)

- (void)x_clearFields {
    NSString *bucketDocumentPath = self.delegate.documentPath;
    self.bucketName.stringValue = bucketDocumentPath.lastPathComponent;
    
    self.bucketPasscode.stringValue = @"";
    self.bucketNewPasscode.stringValue = @"";
    self.bucketNewVerifyPasscode.stringValue = @"";
    
    NSString *passcodeHint = [NSString stringWithContentsOfFile:[bucketDocumentPath stringByAppendingPathComponent:BUCKET_HINT_FILENAME] encoding:NSUTF8StringEncoding error:NULL];
    if (!passcodeHint) {
        passcodeHint = DEFAULT_EMPTY_STRING;
    }
    self.bucketPasscodeHint.stringValue = passcodeHint;
}

@end
