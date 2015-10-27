//
//  EncryptMode.h
//  lolnub
//
//  Created by Anonymous on 8/1/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "ModeController.h"

@interface EncryptMode : ModeController

@property BOOL encryptionSelection;

@property (strong) IBOutlet NSTextField				*bucketPasscode;
@property (strong) IBOutlet NSTextField				*bucketVerifyPasscode;
@property (strong) IBOutlet NSTextField				*bucketPasscodeHint;
@property (strong) IBOutlet NSPopUpButton           *bucketSize;

+ (Nub *)quickCreateNub:(NSString *)typeString;

- (IBAction)encryptBucket:(id)sender;

@end
