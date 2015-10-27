//
//  NubItem.m
//  lolnub
//
//  Created by Anonymous on 10/13/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import "NubItem.h"
#import "NSColor+Archiving.h"


#define DEFAULT_ITEM_TYPE               @"n/a"
#define COLLECTION_KIND_STRING          @"Collection"


NSString *const NubItemTypeAttribute                    = @"type";
NSString *const NubItemUUIDAttribute                    = @"uuid";
NSString *const NubItemNameAttribute                    = @"name";
NSString *const NubItemPathAttribute                    = @"path";
NSString *const NubItemKindAttribute                    = @"kind";
NSString *const NubItemDateCreatedAttribute             = @"dateCreated";
NSString *const NubItemDateModifiedAttribute            = @"dateModified";
NSString *const NubItemDateAddedAttribute               = @"dateAdded";
NSString *const NubItemDateOpenedAttribute				= @"dateOpened";
NSString *const NubItemOpenCountAttribute               = @"openCount";
NSString *const NubItemCodesAttribute                   = @"codes";
NSString *const NubItemRatingAttribute                  = @"rating";
NSString *const NubItemSizeAttribute                    = @"itemSize";
NSString *const NubItemLabelSizeAttribute               = @"labelSize";
NSString *const NubItemLockedAttribute                  = @"locked";
NSString *const NubItemPreviewAttribute                 = @"preview";
NSString *const NubItemPreviewSizeAttribute             = @"previewSize";
NSString *const NubItemIconAttribute                    = @"icon";
NSString *const NubItemLinkedItemsAttribute             = @"links";

static NSWorkspace			*workspace = nil;
static NSMutableDictionary	*typeIndex = nil;
static NSMutableDictionary	*iconIndex = nil;

@interface NubItem ()

@property (strong) NSMutableDictionary *volatileAttributes;

// create the various icon caches
+ (void)x_initCache;

@end


@implementation NubItem

@synthesize attributes;
@synthesize volatileAttributes;

#pragma mark Class

+ (NSMutableDictionary *)defaultItemAttributes {
    NSMutableDictionary *itemAttributes = [NSMutableDictionary dictionary];
    
    itemAttributes[NubItemTypeAttribute]                = @(NubItemTypeSystem);
    itemAttributes[NubItemUUIDAttribute]                = [NSUUID UUID].UUIDString;
    itemAttributes[NubItemDateAddedAttribute]           = [NSDate date];
    itemAttributes[NubItemDateOpenedAttribute]          = [NSDate date];
    
    return itemAttributes;
}

+ (NSMutableDictionary *)defaultBucketAttributes {
	NSMutableDictionary *bucketAttributes = [self defaultItemAttributes];
    
    bucketAttributes[NubItemTypeAttribute]                = @(NubItemTypeSystem);
    bucketAttributes[NubItemPreviewSizeAttribute]         = @(DEFAULT_PREVIEW_SIZE);
    
	return bucketAttributes;
}

+ (NSMutableDictionary *)defaultFileAttributes {
    NSMutableDictionary *fileAttributes = [self defaultItemAttributes];
    
    fileAttributes[NubItemTypeAttribute]                = @(NubItemTypeFile);
    fileAttributes[NubItemOpenCountAttribute]           = @0;
    
    return fileAttributes;
}

+ (NSMutableDictionary *)defaultCollectionAttributes {
    NSMutableDictionary *collectionAttributes = [self defaultItemAttributes];
    
    collectionAttributes[NubItemTypeAttribute]          = @(NubItemTypeCollection);
    collectionAttributes[NubItemKindAttribute]          = COLLECTION_KIND_STRING;
    collectionAttributes[NubItemDateAddedAttribute]     = [NSDate date];
    collectionAttributes[NubItemDateOpenedAttribute]    = [NSDate date];
    collectionAttributes[NubItemLinkedItemsAttribute]   = [NSMutableArray array];
    
    return collectionAttributes;
}

+ (NubItem *)from:(NSMutableDictionary *)itemAttributes {
    return [NubItem from:itemAttributes at:nil];
}

+ (NubItem *)from:(NSMutableDictionary *)itemAttributes at:(NSString *)absolutePath {
    if (!itemAttributes) {
        return nil;
    }
    
    NubItem *item = [[NubItem alloc] init];
    
    [item.attributes addEntriesFromDictionary:itemAttributes];
    
    if (absolutePath) {
        item.volatileAttributes[NubItemPathAttribute] = absolutePath;
    }
    
    return item;
}

+ (NubItem *)collectionItem {
	NubItem *collection = [NubItem from:[self defaultCollectionAttributes]];
    
    collection.attributes[NubItemTypeAttribute] = @(NubItemTypeCollection);
	
    return collection;
}

- (NSString *)description {
    return [@"Item(s): " stringByAppendingFormat:@"%@", self.nubspace];
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.attributes             = [NSMutableDictionary dictionary];
        self.volatileAttributes     = [NSMutableDictionary dictionary];
    }
    
    return self;
}

+ (NubItemMediaKind)mediaKindForPath:(NSString *)absolutePath {
    if (!absolutePath) {
        return NubItemMediaKindSystem;
    }
    
    NSString *pathExt = absolutePath.pathExtension;
    
    if (!pathExt.length) {
        return NubItemMediaKindSystem;
    }
    
    NSString *lowerCasePathExt = pathExt.lowercaseString;
    
    if (!lowerCasePathExt || [lowerCasePathExt isEqualToString:@""]) {
        return NubItemMediaKindSystem;
    }
    
    // highly error prone, lots of threads, doing lots of stuff..
    @synchronized(typeIndex) {
        @try {
            return [typeIndex[lowerCasePathExt] integerValue];
        }
        @catch (NSException *exception) {}
        @finally {}
    }
    
    return (NubItemMediaKind)[NSNumber numberWithInt:NubItemMediaKindOther];
}

+ (NSImage *)previewForPath:(NSString *)absolutePath ofPixelSize:(CGFloat)iconSize asIcon:(BOOL)asIcon {
    // check for and init the index
    if (!typeIndex || !iconIndex) {
        @synchronized(typeIndex) {
            [NubItem x_initCache];
        }
    }
    
    if (asIcon) {
        return [workspace iconForFile:absolutePath];
    }
    
    NSError  *error		= nil;
    NSString *itemType	= nil;
    
    // grab the file UTI
    itemType = [workspace typeOfFile:absolutePath error:&error];
    //NSLog(@"uti: %@ path: %@", itemType, absolutePath);
    
    // return a loading icon if we hit an error this early
    if (!itemType && error) {
        return nil;
    }
    
    // the potential icon
    NSImage *itemIcon = nil;
    
    // we load a custom icon
    // ********************************************************************************
    // NSImage+QuickLook, graciously used from: mattgemmell.com/source
    //
    NSURL *fileURL = [NSURL fileURLWithPath:absolutePath];

    CGImageRef ref = QLThumbnailImageCreate(kCFAllocatorDefault, (__bridge CFURLRef)fileURL, CGSizeMake(iconSize, iconSize), NULL);
    
    if (ref != NULL) {
        // Take advantage of NSBitmapImageRep's -initWithCGImage: initializer, new in Leopard,
        // which is a lot more efficient than copying pixel data into a brand new NSImage.
        // Thanks to Troy Stephens @ Apple for pointing this new method out to me.
        NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:ref];
        
        if (bitmapImageRep) {
            itemIcon = [[NSImage alloc] initWithSize:bitmapImageRep.size];
            
            [itemIcon addRepresentation:bitmapImageRep];
        }
        
        CFRelease(ref);
    }
    // ********************************************************************************
    
    if (!itemIcon) {
        return [workspace iconForFile:absolutePath];
    }
    
    return itemIcon;
}


#pragma mark Instance

- (id)get:(NSString *)attribute {
    // try stored attrs
    id attr = attributes[attribute];
    
    // try in-mem attrs
    if (!attr) {
        attr = volatileAttributes[attribute];
    }
    
    return attr;
}

- (NubItemType)type {
    return [[self get:NubItemTypeAttribute] integerValue];
}

- (NSString *)uuid {
    return [self get:NubItemUUIDAttribute];
}

- (NSString *)nubspace {
    return (self.path).lastPathComponent;
}

- (NSString *)codes {
    return [self get:NubItemCodesAttribute];
}

- (void)setCodes:(NSString *)newCodes {
    if (!newCodes) {
        return;
    }
    
    self.attributes[NubItemCodesAttribute] = newCodes;
}

- (NSString *)path {
    return volatileAttributes[NubItemPathAttribute];
}

- (NSImage *)icon {
    switch (self.type) {
        case NubItemTypeFile:
            return [self x_fileIcon];
            break;
            
        default:
            return [NSImage imageNamed:@"castle-logo"];
    }
    
    return nil;
}

- (NSImage *)preview {
    NSImage *previewImage = volatileAttributes[NubItemPreviewAttribute];
    
    if (!previewImage) {
        return self.icon;
    }
    
    return previewImage;
}

- (void)clearPreview {
    [volatileAttributes removeObjectForKey:NubItemPreviewAttribute];
}

- (NSString *)kind {
    return [self get:NubItemKindAttribute];
}

- (NSNumber *)mediaKind {
    return @([NubItem mediaKindForPath:self.path]);
}

- (NSNumber *)rating {
    NSNumber *x_rating = [self get:NubItemRatingAttribute];

    if (!x_rating) {
        x_rating = DEFAULT_RATING;
    }

    return x_rating;
}

- (void)setRating:(NSNumber *)newRating {
    attributes[NubItemRatingAttribute] = newRating;
}

- (NSNumber *)size {
    return [self get:NubItemSizeAttribute];
}

- (NSDate *)dateAdded {
    return [self get:NubItemDateAddedAttribute];
}

- (NSDate *)dateOpened {
    return [self get:NubItemDateOpenedAttribute];
}

- (NSDate *)dateCreated {
    return [self get:NubItemDateCreatedAttribute];
}

- (NSDate *)dateModified {
    return [self get:NubItemDateModifiedAttribute];
}

- (NSNumber *)openCount {
    return [self get:NubItemOpenCountAttribute];
}


#pragma mark Methods

- (BOOL)isSystemItem {
    return self.type == NubItemTypeSystem;
}

- (BOOL)refresh {
    if (!self.path) {
        return NO;
    }
    
    return NO;
}

- (void)refreshPreviewOfSize:(CGFloat)iconSize completionBlock:(void (^)(void))completeBlock {
    switch (self.type) {
        default:
            [self x_refreshFilePreviewOfSize:iconSize completionBlock:completeBlock];
            break;
            
    }
}

- (NSString *)ratingString {
    switch ([[self get:NubItemRatingAttribute] integerValue]) {
        case NubItemRatingValueHate:
            return @"Hate";
            break;
        case NubItemRatingValueNeutral:
            return @"Neutral";
            break;
        case NubItemRatingValueLike:
            return @"Like";
            break;
        case NubItemRatingValueLove:
            return @"Love";
            break;
    }
    
    return @"n/a";
}

// update openCount
- (void)wasJustOpened {
    NSUInteger openCount = [[self get:NubItemOpenCountAttribute] integerValue];
    
    attributes[NubItemOpenCountAttribute]   = @(openCount + 1);
    attributes[NubItemDateOpenedAttribute]  = [NSDate date];
    
    // @todo mark item as needing saved, and send a note to the world about it
}


#pragma mark Private

- (void)x_refreshFilePreviewOfSize:(CGFloat)iconSize completionBlock:(void (^)(void))completeBlock {
	if (self.isLoadingPreview) {
		return;
	}
    
    // kick off in the background
    self.isLoadingPreview = YES;
    
    NSImage *filePreview = [NubItem previewForPath:self.path ofPixelSize:iconSize asIcon:NO];
    
    if (filePreview) {
        (self.volatileAttributes)[NubItemPreviewAttribute] = filePreview;
    }
    
    self.isLoadingPreview = NO;
    
    if (completeBlock) {
//        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
            completeBlock();
//        }];
    }
}

// (direct, blocking) icons are relatively fast to load
- (NSImage *)x_fileIcon {
    return [NubItem previewForPath:self.path ofPixelSize:MAX_PIXEL_SIZE asIcon:YES];
}

+ (void)x_initCache {
	// only init the cache one time
	if (typeIndex && iconIndex && workspace) {
		return;
	}
    
    workspace = [NSWorkspace sharedWorkspace];
    
    // @todo: use [NSImage imageTypes] to grab UTIs
    
	// create the whitelist of supported preview file types
	typeIndex = [NSMutableDictionary dictionary];
	
    typeIndex[@"jpg"]       = @(NubItemMediaKindImage);
    typeIndex[@"jpeg"]      = @(NubItemMediaKindImage);
    typeIndex[@"png"]       = @(NubItemMediaKindImage);
    typeIndex[@"gif"]       = @(NubItemMediaKindImage);
    typeIndex[@"pdf"]       = @(NubItemMediaKindImage);
    typeIndex[@"bmp"]       = @(NubItemMediaKindImage);
    
    typeIndex[@"avi"]       = @(NubItemMediaKindMovie);
    typeIndex[@"mpg"]       = @(NubItemMediaKindMovie);
    typeIndex[@"mpeg"]      = @(NubItemMediaKindMovie);
    typeIndex[@"mp3"]       = @(NubItemMediaKindMovie);
    typeIndex[@"mp4"]       = @(NubItemMediaKindMovie);
    typeIndex[@"mov"]       = @(NubItemMediaKindMovie);
    typeIndex[@"divx"]      = @(NubItemMediaKindMovie);
    typeIndex[@"xvid"]      = @(NubItemMediaKindMovie);
    typeIndex[@"wmv"]       = @(NubItemMediaKindMovie);
    
    //	NSNumber *whitelist = @YES;
    //
    //	typeIndex[@"com.adobe.pdf"] = whitelist;
    //	typeIndex[@"com.adobe.photoshop-image"] = whitelist;
    //	typeIndex[@"com.apple.icns"] = whitelist;
    //	typeIndex[@"com.apple.protected-mpeg-4-video"] = whitelist;
    //	typeIndex[@"com.apple.quicktime-movie"] = whitelist;
    //	typeIndex[@"com.compuserve.gif"] = whitelist;
    //	typeIndex[@"public.avi"] = whitelist;
    //	typeIndex[@"public.jpeg"] = whitelist;
    //	typeIndex[@"public.mpeg"] = whitelist;
    //	typeIndex[@"public.mpeg-4"] = whitelist;
    //	typeIndex[@"public.plain-text"] = whitelist;
    //	typeIndex[@"public.png"] = whitelist;
    //	typeIndex[@"public.rtf"] = whitelist;
    
	iconIndex = [NSMutableDictionary dictionary];	
}
@end
