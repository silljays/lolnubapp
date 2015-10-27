//
//  NubWindowController.h
//  lolnub
//
//  Created by Anonymous on 10/31/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NubBrandTrafficButton.h"

@interface NubWindowController : NSWindowController

@property (weak) IBOutlet NubBrandTrafficButton    *closeButton;
@property (weak) IBOutlet NubBrandTrafficButton    *panicButton;
@property (weak) IBOutlet NubBrandTrafficButton    *minimizeButton;
@property (weak) IBOutlet NubBrandTrafficButton    *zoomButton;

// link to our Nub document
- (id)nub;

- (IBAction)performMiniaturize:(id)sender;

@end
