//
//  NubItem.h
//  lolnub
//
//  Created by Anonymous on 10/13/13.
//  Copyright (c) 2015 lolnub.com developers All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Bot.h"
#import <QuickLook/QuickLook.h>

typedef NS_ENUM(NSInteger, NubItemType) {
    NubItemTypeSystem       = 0,
    NubItemTypeFile         = 1,
    NubItemTypeCollection   = 5,
    NubItemTypeScene        = 7
};

typedef NS_ENUM(NSInteger, NubItemMediaKind) {
    NubItemMediaKindSystem = 0,
    NubItemMediaKindImage,
    NubItemMediaKindMovie,
    NubItemMediaKindOther,
};

typedef NS_ENUM(NSInteger, NubItemRatingValue) {
    NubItemRatingValueHate          = -1,
    NubItemRatingValueNeutral		= 0,
    NubItemRatingValuePrivate1		= 1,
    NubItemRatingValuePrivate2		= 2,
    NubItemRatingValueLike			= 3,
    NubItemRatingValuePrivate4		= 4,
    NubItemRatingValueLove			= 5
};


extern NSString *const NubItemTypeAttribute;
extern NSString *const NubItemUUIDAttribute;
extern NSString *const NubItemNameAttribute;
extern NSString *const NubItemPathAttribute;
extern NSString *const NubItemKindAttribute;
extern NSString *const NubItemDateCreatedAttribute;
extern NSString *const NubItemDateModifiedAttribute;
extern NSString *const NubItemDateAddedAttribute;
extern NSString *const NubItemDateOpenedAttribute;
extern NSString *const NubItemOpenCountAttribute;
extern NSString *const NubItemCodesAttribute;
extern NSString *const NubItemRatingAttribute;
extern NSString *const NubItemSizeAttribute;
extern NSString *const NubItemLabelSizeAttribute;
extern NSString *const NubItemLockedAttribute;
extern NSString *const NubItemPreviewAttribute;
extern NSString *const NubItemPreviewSizeAttribute;
extern NSString *const NubItemIconAttribute;
extern NSString *const NubItemLinkedItemsAttribute;


@interface NubItem : NSObject

@property (strong)  NSMutableDictionary     *attributes;

@property BOOL isLoadingPreview;
@property BOOL isFresh;

// default attributes for various types of items
+ (NSMutableDictionary *)defaultItemAttributes;
+ (NSMutableDictionary *)defaultBucketAttributes;
+ (NSMutableDictionary *)defaultFileAttributes;
+ (NSMutableDictionary *)defaultCollectionAttributes;

+ (NubItem *)from:(NSMutableDictionary *)itemAttributes;
+ (NubItem *)from:(NSMutableDictionary *)itemAttributes at:(NSString *)absolutePath;
+ (NubItem *)collectionItem;

// accessors
- (id)get:(NSString *)attribute;

// virtual methods
- (NubItemType)type;
- (NSString *)uuid;
- (NSString *)nubspace;
- (NSString *)codes;
- (void)setCodes:(NSString *)newCodes;
- (NSString *)path;

- (NSImage *)icon;
- (NSImage *)preview;
- (void)clearPreview;
- (NSString *)kind;
- (NSNumber *)mediaKind;
- (NSNumber *)rating;
- (void)setRating:(NSNumber *)newRating;
- (NSNumber *)size;
- (NSString *)dateAdded;
- (NSString *)dateOpened;
- (NSString *)dateCreated;
- (NSString *)dateModified;
- (NSNumber *)openCount;

// should be hidden
- (BOOL)isSystemItem;

// load attributes from storage + file system
- (void)refreshPreviewOfSize:(CGFloat)iconSize completionBlock:(void (^)(void))completeBlock;
- (BOOL)refresh;

// update openCount
- (void)wasJustOpened;

// other
- (NSString *)ratingString;

// return the mediaKind for the given path
+ (NubItemMediaKind)mediaKindForPath:(NSString *)absolutePath;

// return an icon for absolutePath (based on the cache, the file type, a generic icon, etc.)
+ (NSImage *)previewForPath:(NSString *)absolutePath ofPixelSize:(CGFloat)iconSize asIcon:(BOOL)asIcon;

@end
