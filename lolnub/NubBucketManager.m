//
//  NubBucketManager.m
//  lolnub
//
//  Created by Me on 10/13/13.
//  Copyright (c) 2014 lolnub.com developers All rights reserved.
//

NSString *const NubDidAddItemsNotification       = @"NubDidAddItemsNotification";
NSString *const NubDidRemoveItemsNotification    = @"NubDidRemoveItemsNotification";
NSString *const NubShouldImportItemsNotification = @"NubShouldImportItemsNotification";


#define FILE_SYSTEM_ERROR               -1
#define STATIC_ITEM_COUNT               0 // some items are stored but not shown in the UX

#define PATHKEYMAP_FILENAME             @".nub.pathKeyMap"
#define SHARD_INDEX_BACKUP_FILENAME     @".nub.shardIndex.backup"

#define INDEX_SHARD_LENGTH              1
#define STORAGE_SHARD_LENGTH            2

#define INIT_IMPORT_DELAY               5

#import "NubBucketManager.h"
#import "NSFileManager+Hashing.h"


@interface NubBucketManager ()

@property NSString              *storagePath;
@property NSString              *indexPath;

@property NSMutableDictionary	*shardIndex;
@property NSMutableDictionary   *pathKeyMap;

@property NSString              *operationsPath;

- (NSString *)x_hashOfFileOrPath:(NSString *)absolutePath;

- (BOOL)x_checkStorageStructure:(NSString *)absolutePath;
- (BOOL)x_checkIndexStructure:(NSString *)absolutePath;
- (BOOL)x_checkOperationsStructure:(NSString *)absolutePath;

- (void)x_importOperations;
- (NubItem *)x_importFileAtPath:(NSString *)absolutePath;
- (void)x_importFolderAtPath:(NSString *)absolutePath;

@end


@implementation NubBucketManager

@synthesize rootPath;
@synthesize storagePath;
@synthesize indexPath;
@synthesize shardIndex;
@synthesize pathKeyMap;
@synthesize observers;

#pragma mark General

- (id)initWithPath:(NSString *)absolutePath {
    self = [super init];
    
    if (self) {
        self.rootPath = absolutePath;
        
        NSString *versionedPath = [absolutePath stringByAppendingPathComponent:STORAGE_VERSION];
        
        // init the file storage system
        self.storagePath = [versionedPath stringByAppendingPathComponent:@"storage"];
        if (![self x_checkStorageStructure:versionedPath]) {
            return nil;
        }
        
        // init the index features
        self.indexPath = [versionedPath stringByAppendingPathComponent:@"index"];
        if (![self x_checkIndexStructure:versionedPath]) {
            return nil;
        }
        
        self.operationsPath = [versionedPath stringByAppendingString:@"operations"];
        if (![self x_checkOperationsStructure:versionedPath]) {
            return nil;
        }
        
        // setup our observers (for new items)
        self.observers = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(x_importOperations) name:NubShouldImportItemsNotification object:self];
        
        [NSTimer scheduledTimerWithTimeInterval:INIT_IMPORT_DELAY target:self selector:@selector(x_importOperations) userInfo:nil repeats:NO];
    }
    
    return self;
}

- (BOOL)saveItems {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    // 1) SAVE THE SHARDS
    [self.shardIndex enumerateKeysAndObjectsUsingBlock:^(id member, id objects, BOOL *stop) {
#ifdef DEBUG_CAVEMAN
        NSLog(@"shard: %@ count: %ld", member, [objects count]);
#endif
        
        if (![NSKeyedArchiver archiveRootObject:objects toFile:[indexPath stringByAppendingPathComponent:member]]) {
            @throw @"unable to archiveRootObject of shardIndex";
        }
    }];
    
    // 2) SAVE THE PATHKEYMAP
    if (![NSKeyedArchiver archiveRootObject:pathKeyMap toFile:[indexPath stringByAppendingPathComponent:PATHKEYMAP_FILENAME]]) {
        @throw @"unable to archiveRootObject of pathKeyMap";
    }
    
    // backup the index folder
    // @todo compress the backup folder
    NSError *error = nil;
    
    // delete the previous backup (ignore errors thrown when the backup doesn't exist, i.e. on first launch)
    [self removeItemAtPath:[[indexPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:SHARD_INDEX_BACKUP_FILENAME] error:NULL];
    
    // create the new backup
    if (![self copyItemAtPath:indexPath toPath:[[indexPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:SHARD_INDEX_BACKUP_FILENAME] error:&error]) {
        @throw @"unable to save itemIndex because the fileManager returned an error";
    }
    
    return YES;
}

- (NSUInteger)storedItemsCount {
    return [pathKeyMap.allKeys count] - STATIC_ITEM_COUNT;
}

#pragma mark Observers

- (void)forwardItemsForObserver:(id)observer {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    return [self forwardItemsForObserver:observer registerForUpdates:NO];
}

- (void)forwardItemsForObserver:(id)observer registerForUpdates:(BOOL)registerUpdates {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    // don't forward items to a nil observer
    if (!observer) {
        return;
    }
    
    // update the observer with our current items
    @synchronized(self) {
        [[self.shardIndex allValues] enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id shard, NSUInteger subIndex, BOOL *stop) {            
            NSArray *shardKeys = [shard allKeys];
            __block NSMutableArray *items = [NSMutableArray arrayWithCapacity:shardKeys.count];

            [shardKeys enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id keyPath, NSUInteger hashIndex, BOOL *stop) {
                // push the internal items *UP* to an observer (typically a NubItemSource..)
                [items addObject:[self itemFromKeyPath:keyPath]];
            }];
            
            [observer addItems:items];
        }];
    }
    
    // does the object want to follow updates to items?
    if (registerUpdates) {
        if (![self.observers containsObject:observer]) {
            [self.observers addObject:observer];
        }
    }
}

- (void)observeAddedItems:(NSArray *)items {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    [observers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NubItemSource *observer, NSUInteger _observerIndex, BOOL *stopObserver) {
        [observer addItems:items];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NubDidAddItemsNotification object:self userInfo:@{@"items" : items}];
}

- (void)observeRemovedItems:(NSArray *)items {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    [observers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NubItemSource *observer, NSUInteger _observerIndex, BOOL *stopObserver) {
        [items enumerateObjectsUsingBlock:^(NubItem *item, NSUInteger _itemIndex, BOOL *stopItem) {
            [observer removeItems:@[item]];
        }];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NubDidRemoveItemsNotification object:self userInfo:@{@"items" : items}];
}

- (void)stopObserving:(id)observer {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    if (![observers containsObject:observer]) {
        return;
    }
    
    [observers removeObject:observer];
    
    [observer reloadData];
}

#pragma mark Files

- (void)importPaths:(NSArray *)absolutePaths {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    // #todo: add operations for each and every subPath of absolutePath
    
    for (NSString *absolutePath in absolutePaths) {
        NSDictionary *operationDictionary = @{@"path": absolutePath};
        
        NSString *tempPath = [self.operationsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.operation", (arc4random())]];
        
        [operationDictionary writeToFile:tempPath atomically:YES];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NubShouldImportItemsNotification object:self];

    [self saveItems];
}

- (void)x_importOperations {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    NSError *error = nil;
    
    NSArray *operations = [self contentsOfDirectoryAtPath:[self operationsPath] error:&error];
    
    [operations enumerateObjectsUsingBlock:^(id path, NSUInteger index, BOOL *stop) {
        
        // setup the operations
        
        if (![path hasSuffix:@"operation"]) {
            return;
        }
        
        NSString *currentOperationPath = [self.operationsPath stringByAppendingPathComponent:path];
        NSString *workingOperationPath = [currentOperationPath stringByAppendingPathExtension:@"working"];
        
        [self moveItemAtPath:currentOperationPath toPath:workingOperationPath error:NULL];
        
        NSDictionary *operation = [NSDictionary dictionaryWithContentsOfFile:workingOperationPath];
        
        if (!operation) {
            NSLog(@"*** error: unable to load operation");
            
            [self moveItemAtPath:workingOperationPath toPath:currentOperationPath error:NULL];
            
            return;
        }
        
        // check the operations item
        
        NSString *absolutePath = operation[@"path"];
        
        BOOL absolutePathExists         = NO;
        BOOL absolutePathIsDirectory    = NO;
        
        absolutePathExists = [self fileExistsAtPath:absolutePath isDirectory:&absolutePathIsDirectory];
        
        // path must exist
        if (absolutePathExists && absolutePathIsDirectory) {
            [self x_importFolderAtPath:absolutePath];
        }
        else if (absolutePathExists && !absolutePathIsDirectory) {
            if (![self x_importFileAtPath:absolutePath]) {
                NSError *removeError = nil;
                
                [self removeItemAtPath:workingOperationPath error:&removeError];
                
                if (removeError) {
                    NSLog(@"*** error: %@", removeError);
                }
            }
        }
    }];
}

- (void)x_importFolderAtPath:(NSString *)absolutePath {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    NSError *error = nil;
    
    for	(NSString *subPath in [self contentsOfDirectoryAtPath:absolutePath error:&error]) {
        NSString *absoluteSubPath = [absolutePath stringByAppendingPathComponent:subPath];
        
        BOOL absoluteSubPathExists         = NO;
        BOOL absoluteSubPathIsDirectory    = NO;
        
        absoluteSubPathExists = [self fileExistsAtPath:absoluteSubPath isDirectory:&absoluteSubPathIsDirectory];
        
        // path must exist
        if (absoluteSubPathIsDirectory) {
            [self x_importFolderAtPath:absoluteSubPath];
        }
        else if (absoluteSubPathExists && !absoluteSubPathIsDirectory) {
            [self x_importFileAtPath:absoluteSubPath];
        }
    }
}

- (NubItem *)x_importFileAtPath:(NSString *)absolutePath {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    NSError *error = nil;
    
    // don't import invisible files
    if ([[absolutePath lastPathComponent] hasPrefix:@"."]) {
        NSLog(@"*** skipping dot: %@", absolutePath);
        
        return nil;
    }
    
    // default attributes
    NSMutableDictionary *itemAttributes = [NubItem defaultFileAttributes];
    
    // grab the freshly assigned UUID of the item
    NSString *fileKeyPath = itemAttributes[NubItemUUIDAttribute];
    
    // check for duplicate items
    NSString *fileHash = [self x_hashOfFileOrPath:absolutePath];
    
    if (pathKeyMap[fileHash]) {
        NSLog(@"*** skipping duplicate: %@ path: %@", fileKeyPath, absolutePath);
        
        return nil;
    }
    
    // pick the storage shard
    NSString *fileStorageShard = [fileKeyPath substringToIndex:STORAGE_SHARD_LENGTH];
    NSString *fileStorageShardPath = [[storagePath stringByAppendingPathComponent:fileStorageShard] stringByAppendingPathComponent:fileKeyPath];
    
    // create the shard directory, ignore errors
    [self createDirectoryAtPath:fileStorageShardPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    // the final path the file has inside our storage engine
    NSString *filePath = [fileStorageShardPath stringByAppendingPathComponent:[absolutePath lastPathComponent]];
    
    // copy the file to the storage shard with the original extension in place
    
    [self copyItemAtPath:absolutePath toPath:filePath error:&error];
    
    if (error) {
        DebugLog();
        NSLog(@"***caught: %@", error);
        
        return nil;
    }
    
    // seed with the file path
    itemAttributes[NubItemNameAttribute] = [absolutePath lastPathComponent];
    // set the folder the path was in as the first "tag"
    itemAttributes[NubItemCodesAttribute] = [absolutePath stringByDeletingLastPathComponent];
    
    // map the fileHash to the keyPath
    pathKeyMap[[self x_hashOfFileOrPath:absolutePath]] = itemAttributes[NubItemUUIDAttribute];
    
    // instance the item
    NubItem *newItem = [NubItem from:itemAttributes at:filePath];
    
    // refresh the attributes
    [newItem refresh];
    
    @synchronized(self) {
        [self setAttributes:newItem.attributes forKeyPath:newItem.uuid];
    }
    
    [self observeAddedItems:@[newItem]];
    
    return newItem;
}

- (void)removeItems:(NSArray *)items {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    //#todo: fix the removeItems code
    
    NSMutableArray *removedItems = [NSMutableArray array];
    
    for (NubItem *item in items) {
        NSError *error = nil;
        
        if ([item isSystemItem]) {
            continue;
        }
        
        [self removeAttributesForItem:item];
        
        // try to delete the item from the fileSystem
        [self removeItemAtPath:item.path error:&error];
        
        if (error) {
            DebugLog();
            NSLog(@"***error: %@", error);
            
            continue;
        }
        
        [removedItems addObject:item];
    }

    [self saveItems];

    [self observeRemovedItems:removedItems];
}

- (void)exportStoredItemsToPath:(NSString *)absolutePath {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    // iterate the Nub and copy all files to the new location
    [[shardIndex allValues] enumerateObjectsUsingBlock:^(id shard, NSUInteger shardIndex, BOOL *stop) {
        [[shard allKeys] enumerateObjectsUsingBlock:^(id itemUUID, NSUInteger hashIndex, BOOL *stop) {
            if (itemUUID) {
                
                NSString *itemPath = [self filePathForKeyPath:itemUUID];
                
                if (itemPath) {
                    NSError *error = nil;
                    
                    [self copyItemAtPath:itemPath toPath:[absolutePath stringByAppendingPathComponent:[itemPath lastPathComponent]] error:&error];
                    
                    // #todo: add error handling bots
                    //                    if (error) {
                    //                        NSAlert *alert = [[NSAlert alloc] init];
                    //
                    //                        [alert addButtonWithTitle:@"OK"];
                    //                        [alert setMessageText:@"An unknown error happened while exporting items to the place you selected."];
                    //                        [alert setInformativeText:@"Something about the disk has likely changed since you began the export. Try again or contact support."];
                    //                        [alert setAlertStyle:NSWarningAlertStyle];
                    //
                    //                        [alert runModal];
                    //                    }
                }
            }
        }];
    }];
}

#pragma mark Items

- (NubItem *)itemFromKeyPath:(NSString *)keyPath {
    id attributes = [self attributesForKeyPath:keyPath];
    
    return [NubItem from:attributes at:[self filePathForItemAttributes:attributes]];
}

- (NSString *)filePathForItem:(NubItem *)item {
    return [self filePathForKeyPath:item.uuid];
}

- (NSString *)filePathForKeyPath:(NSString *)keyPath {
    return [self filePathForItemAttributes:[self attributesForKeyPath:keyPath]];
}

- (NSString *)filePathForItemAttributes:(NSDictionary *)attributes {
    // rewrote to not touch the file system, at the cost of possibly returning non-existent paths
    NSString *keyPath           = attributes[NubItemUUIDAttribute];
    
    NSString *shardPath         = [[keyPath substringToIndex:STORAGE_SHARD_LENGTH] stringByAppendingPathComponent:keyPath];
    NSString *filePath          = [shardPath stringByAppendingPathComponent:attributes[NubItemNameAttribute]];
    
    return [storagePath stringByAppendingPathComponent:filePath];
}

#pragma mark KeyPath

- (NSMutableDictionary *)attributesForKeyPath:(NSString *)keyPath {
    return shardIndex[[keyPath substringToIndex:INDEX_SHARD_LENGTH]][keyPath];
}

- (void)setAttributes:(NSMutableDictionary *)attributes forKeyPath:(NSString *)keyPath {
    NSMutableDictionary *shard = shardIndex[[keyPath substringToIndex:INDEX_SHARD_LENGTH]];
    
    @synchronized(shard) {
        shard[keyPath] = attributes;
    }
}

- (void)removeAttributesForItem:(NubItem *)item {
    NSString *keyPath = item.uuid;
    
    NSMutableDictionary *shard = shardIndex[[keyPath substringToIndex:INDEX_SHARD_LENGTH]];
    
    @synchronized(shard) {
        [shard removeObjectForKey:keyPath];
    }
    
    @synchronized(pathKeyMap) {
        [pathKeyMap removeObjectForKey:[self x_hashOfFileOrPath:item.path]];
    }
}

#pragma mark Utilities

- (NSString *)x_hashOfFileOrPath:(NSString *)absolutePath {
    // 1) try to hash the file
    NSString *filePathHash = [self hashOfFileAtPath:absolutePath];
    
    // 2) if the file does NOT hash, then hash the path of the attempted file
    if (!filePathHash) {
        filePathHash = [self hashForString:absolutePath];
    }
    
    return filePathHash;
}

#pragma mark Health

- (BOOL)x_checkStorageStructure:(NSString *)absolutePath {
    NSError *error = nil;
    
    // check that our *entire* storage system already exists
    if (![self fileExistsAtPath:storagePath]) {
        // otherwise we need to create it here
        [self createDirectoryAtPath:storagePath withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error) {
            DebugLog();
            NSLog(@"***error: %@", error);
            return NO;
        }
    }
    
    // check and create the individual shard directories
    NSArray *shardArray = @[@"a", @"b", @"c", @"d", @"e", @"f", @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9"];
    NSString *shardMemberPath = nil;
    
    for (NSString *outerShard in shardArray) {
        for (NSString *innerShard in shardArray) {
            shardMemberPath = [storagePath stringByAppendingPathComponent:[outerShard stringByAppendingString:innerShard]];
            
            if (![self fileExistsAtPath:shardMemberPath]) {
                
                [self createDirectoryAtPath:shardMemberPath withIntermediateDirectories:YES attributes:nil error:&error];
                
                if (error) {
                    DebugLog();
                    NSLog(@"***error: %@", error);
                    return NO;
                }
            }
        }
    }
    
    return [self fileExistsAtPath:storagePath];
}

- (BOOL)x_checkIndexStructure:(NSString *)absolutePath {
    
    NSError *error = nil;
    
    // 1) CHECK OR CREATE THE ROOT DIRECTORY OUR INDICES USE
    if (![self fileExistsAtPath:indexPath]) {
        [self createDirectoryAtPath:indexPath withIntermediateDirectories:NO attributes:NULL error:&error];
        
        if (error) {
            DebugLog();
            NSLog(@"***error: %@", error);
            
            return NO;
        }
    }
    
    // 2) SHARD
    if (!self.shardIndex) {
        self.shardIndex = [NSMutableDictionary dictionary];
        
        shardIndex[@"0"] = @"";
        shardIndex[@"1"] = @"";
        shardIndex[@"2"] = @"";
        shardIndex[@"3"] = @"";
        shardIndex[@"4"] = @"";
        shardIndex[@"5"] = @"";
        shardIndex[@"6"] = @"";
        shardIndex[@"7"] = @"";
        shardIndex[@"8"] = @"";
        shardIndex[@"9"] = @"";
        shardIndex[@"A"] = @"";
        shardIndex[@"B"] = @"";
        shardIndex[@"C"] = @"";
        shardIndex[@"D"] = @"";
        shardIndex[@"E"] = @"";
        shardIndex[@"F"] = @"";
        shardIndex[@"G"] = @"";
        shardIndex[@"H"] = @"";
        shardIndex[@"I"] = @"";
        shardIndex[@"J"] = @"";
        shardIndex[@"K"] = @"";
        shardIndex[@"L"] = @"";
        shardIndex[@"M"] = @"";
        shardIndex[@"N"] = @"";
        shardIndex[@"O"] = @"";
        shardIndex[@"P"] = @"";
        shardIndex[@"Q"] = @"";
        shardIndex[@"R"] = @"";
        shardIndex[@"S"] = @"";
        shardIndex[@"T"] = @"";
        shardIndex[@"U"] = @"";
        shardIndex[@"V"] = @"";
        shardIndex[@"W"] = @"";
        shardIndex[@"X"] = @"";
        shardIndex[@"Y"] = @"";
        shardIndex[@"Z"] = @"";
    }
    
    // create or load the individual shards
    NSString *memberPath = nil;
    
    for (NSString *member in [shardIndex allKeys]) {
        memberPath = [indexPath stringByAppendingPathComponent:member];
        
        @try {
            [self.shardIndex setObject:[NSKeyedUnarchiver unarchiveObjectWithFile:memberPath] forKey:member];
        }
        @catch (NSException * e) {
            shardIndex[member] = [NSMutableDictionary dictionary];
        }
    }
    
    // 3) PATHKEYMAP
    NSString *pathKeyMapPath = [indexPath stringByAppendingPathComponent:PATHKEYMAP_FILENAME];
    
    @try {
        self.pathKeyMap = [NSKeyedUnarchiver unarchiveObjectWithFile:pathKeyMapPath];
    }
    @catch (NSException * e) {
        self.pathKeyMap = [NSMutableDictionary dictionary];
    }
    
    return YES;
}

- (BOOL)x_checkOperationsStructure:(NSString *)absolutePath {
    NSError *error = nil;
    
    // check and create the file storage directory
    [self setOperationsPath:[absolutePath stringByAppendingPathComponent:@"operations"]];
    
    if (![self fileExistsAtPath:[self operationsPath]]) {
        
        [self createDirectoryAtPath:[self operationsPath] withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error) {
            NSLog(@"***error: %@", error);
            
            return NO;
        }
    }
    
    return YES;
}

@end
