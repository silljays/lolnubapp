//
//  WebMode.h
//  lolnub
//
//  Created by Anonymous on 7/26/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "ModeController.h"
#import "WebKit/WebKit.h"

@interface WebMode : ModeController<NSURLDownloadDelegate>


@property (strong)  IBOutlet        WebView         *webView;
@property (strong)  IBOutlet        NSMenu          *itemContextMenu;

@property (strong)                  id              clickedElement;


// open the app's homepage
- (IBAction)openDefaultURI:(id)sender;

// download the current mainFrame's contents to the nubspace.
- (IBAction)downloadInternal:(id)sender;

@end
