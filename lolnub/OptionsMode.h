//
//  OptionsMode.h
//  lolnub
//
//  Created by Anonymous on 9/19/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "ModeController.h"

@interface OptionsMode : ModeController

@property (strong) IBOutlet NSTextField           *bucketName;
@property (strong) IBOutlet NSSecureTextField     *bucketPasscode;
@property (strong) IBOutlet NSSecureTextField     *bucketNewPasscode;
@property (strong) IBOutlet NSTextField			*bucketNewVerifyPasscode;
@property (strong) IBOutlet NSTextField			*bucketPasscodeHint;

// change the Nub passcode/hint
- (IBAction)updatePasscode:(id)sender;

@end
