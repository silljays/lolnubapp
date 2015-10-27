//
//  NubTrafficButton.h
//  lolnub
//
//  Created by Anonymous on 11/9/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "NubBrandButton.h"

extern NSString *const NubBrandTrafficButtonEventNotification;
extern NSString *const NubBrandTrafficButtonMouseExitedNotification;

@interface NubBrandTrafficButton : NubBrandButton

@property BOOL isHovering;
@property BOOL isRemote;

@property (strong) NSColor *gradientBaseColor;

- (void)remoteMouseExited:(NSNotification *)note;
- (void)remoteMouseEntered:(NSNotification *)note;

@end
