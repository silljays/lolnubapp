//
//  DecryptMode.h
//  lolnub
//
//  Created by Anonymous on 8/1/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "ModeController.h"

@interface DecryptMode : ModeController

@property (strong) IBOutlet NSTextField           *bucketName;
@property (strong) IBOutlet NSTextField           *bucketHint;
@property (strong) IBOutlet NSSecureTextField     *bucketPasscode;

- (IBAction)decryptBucket:(id)sender;

@end

