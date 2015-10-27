//
//  NubBucketManager.h
//  lolnub
//
//  Created by Me on 10/13/13.
//  Copyright (c) 2014 lolnub.com developers All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+ByteCount.h"
#import "NubItemSource.h"
#import "NubItem.h"
#import "Bot.h"

extern NSString *const NubDidAddItemsNotification;
extern NSString *const NubDidRemoveItemsNotification;
extern NSString *const NubShouldImportItemsNotification;

@interface NubBucketManager : NSFileManager

@property NSString              *rootPath;
@property NSMutableArray        *observers;

#pragma mark General

// create/verify the bucketManager "inside" the Nub at absolutePath
- (id)initWithPath:(NSString *)absolutePath;

// return the count of all items
- (NSUInteger)storedItemsCount;

#pragma mark Observers

// push all items with out registering future interest
- (void)forwardItemsForObserver:(id)observer;

// push all items to the observer + register observer as interested in add/remove item notifications
- (void)forwardItemsForObserver:(id)observer registerForUpdates:(BOOL)notify;

#pragma mark Files

// add a file or folder from absolutePath to the storage engine
// * todo: this method will not add/descend invisible .dot files/folders
- (void)importPaths:(NSArray *)absolutePaths;

// delete an array of items from the bucketManager
- (void)removeItems:(NSArray *)items;

// copy all items to an external path
- (void)exportStoredItemsToPath:(NSString *)absolutePath;

#pragma mark Items

// return an item instance from the given keyPath
- (NubItem *)itemFromKeyPath:(NSString *)keyPath;

// return the physical path in the storage engine for the given item
- (NSString *)filePathForItem:(NubItem *)item;

// return the physical path in the storage engine for the given hash
- (NSString *)filePathForKeyPath:(NSString *)keyPath;

// return a string smashed from the (item) attributes
- (NSString *)filePathForItemAttributes:(NSDictionary *)attributes;

#pragma mark KeyPaths

// return the indexed file attributes for the given hash or nil if nothing is found
- (NSMutableDictionary *)attributesForKeyPath:(NSString *)keyPath;

// set the root object for absolutePath
- (void)setAttributes:(NSMutableDictionary *)attributes forKeyPath:(NSString *)keyPath;

// delete the item from all indexes + the storage Nub
- (void)removeAttributesForItem:(NubItem *)item;

// save in memory objects to disk
- (BOOL)saveItems;

@end

@protocol NubObserver
@required

- (void)addItems:(NSArray *)items;
- (void)removeItems:(NSArray *)items;

@end
