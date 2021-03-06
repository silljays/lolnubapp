//
//  lolnub-Bridging-Header.h
//  lolnub
//
//  Created by Anonymous on 7/31/15.
//  Copyright © 2015 lolnub.com. All rights reserved.
//

#ifndef lolnub_Bridging_Header_h
#define lolnub_Bridging_Header_h

//
// Prefix header for all source files of the 'lolnub' target in the 'lolnub' project
//

#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#endif

// caveman, baby
#define DEBUG_LOG                       1

#ifdef DEBUG_LOG
#   define DebugLog(); NSLog(@"\t%s", __PRETTY_FUNCTION__);
#else
#   define DebugLog()
#endif


// WARNING: bump the STORAGE_VERSION for *all* file storage changes.
#define STORAGE_VERSION                 @".v5"

// Units

#ifndef KILOBYTE
#define KILOBYTE						1000
#endif
#ifndef MEGABYTE
#define MEGABYTE						1000000
#endif
#ifndef GIGABYTE
#define GIGABYTE						1000000000
#endif
#ifndef TERABYTE
#define TERABYTE						1000000000000
#endif


// Random

#define CLIP_RADIUS                     3

#define MIN_PIXEL_SIZE                  32.0
#define MAX_PIXEL_SIZE					1024.0

#define PARANOID_ENCRYPTION_LEVEL		1
#define PARANOID_ENCRYPTION_TYPE		@"AES-128"
#define DELUSIONAL_ENCRYPTION_LEVEL		2
#define DELUSIONAL_ENCRYPTION_TYPE		@"AES-256"

#define WALLPAPER_FILENAME              @"wallpaper-dark"
#define DOCUMENT_EXTENSION              @"nub"


// Keys

#define BUCKET_HINT_FILENAME            @".nub.hint.name"
#define BUCKET_BOT_ITEMS_KEY            @".nub.bot.items.key"
#define BUCKET_WINDOW_FRAME_KEY         @".nub.window.frame"
#define BUCKET_CURRENT_MODE_KEY         @".nub.current.mode.key"
#define BUCKET_ITEM_MODE_SESSIONS_KEY   @".nub.mode.item.sessions.key"
#define BUCKET_NUB_MODE_STORAGE_KEY     @".nub.mode.storage.key"


// URIs

#define URI_DEFAULT                     @"https://localhost:8443/"
#define URI_PRIVACY                     @"https://localhost:8443/page/privacy"
#define URI_SUPPORT                     @"https://localhost:8443/page/help"
#define URI_VERSION                     @"https://localhost:8443/page/lolnubapp.version"


// Defaults

#define DEFAULT_PASSCODE                @"lolnub"

#define DEFAULT_URI                     URI_DEFAULT // used everywhere
#define DEFAULT_BEAM                    @"https://localhost:8443/"   // used everywhere
#define DEFAULT_RATING                  0 // i.e. neutral
#define DEFAULT_EMPTY_STRING            @"n/a"
#define DEFAULT_BUCKET_MODE             NubBucketMode
#define DEFAULT_BUCKET_MB_SIZE          20000
#define DEFAULT_PIXEL_SIZE              128.0
#define DEFAULT_PREVIEW_SIZE			DEFAULT_PIXEL_SIZE
#define DEFAULT_LABEL_SIZE				15.0
#define DEFAULT_ENCRYPTION_TYPE         PARANOID_ENCRYPTION_TYPE
#define DEFAULT_QUERY_STRING            @""
#define DEFAULT_CAKE_STRING             @"@cake)readme"


// Imports

#import "AppController.h"
#import "Bot.h"
#import "Nub.h"
#import "NSString+ByteCount.h"
#import "NSFileManager+Stats.h"
#import "NubMedia.h"
#import "NubBucketManager.h"

#endif /* lolnub_Bridging_Header_h */
