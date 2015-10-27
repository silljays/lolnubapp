//
//  NubItemSource.m
//  lolnub
//
//  Created by Me on 10/13/13.
//  Copyright (c) 2014 lolnub.com developers All rights reserved.
//

#import "NubItemSource.h"

#define DEFAULT_SESSION_LIMIT               1000000

NSString *const NubItemSourceDidUpdateNotification  = @"NubItemSourceDidUpdateNotification";

NSString *const NubItemDefaultAttribute      = @"default";
NSString *const NubItemQueryAttribute        = @"query";
NSString *const NubItemImagesAttribute       = @"images";
NSString *const NubItemMoviesAttribute       = @"movies";
NSString *const NubItemOthersAttribute       = @"others";
NSString *const NubItemArrangeByAttribute    = @"arrangeby";
NSString *const NubItemOrderByAttribute      = @"orderby";
NSString *const NubItemLimitAttribute        = @"limit";
NSString *const NubItemCallbackAttribute     = @"callback";


@interface NubItemSource ()

@property (strong) NSMutableArray       *x_allItems;
@property (strong) NSMutableArray       *x_items;


- (NSMutableArray *)x_transformItems:(NSMutableArray *)rawItems;

@end


@implementation NubItemSource

@synthesize dataSource;
@synthesize attributes;
@synthesize x_allItems;
@synthesize x_items;

+ (NSMutableDictionary *)defaultSessionAttributes {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
    attributes[NubItemNameAttribute]        = @"untitled";
    attributes[NubItemImagesAttribute]      = @(1);
    attributes[NubItemMoviesAttribute]      = @(1);
    attributes[NubItemOthersAttribute]      = @(1);
    attributes[NubItemArrangeByAttribute]   = @(NubItemArrangeByDateAdded);
    attributes[NubItemOrderByAttribute]     = @(NubItemOrderByDescending);
    attributes[NubItemLimitAttribute]       = @(DEFAULT_SESSION_LIMIT);
    
    return attributes;
}

- (id)initWithDataSource:(id)newDataSource {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    return [self initWithDataSource:newDataSource andAttributes:[NubItemSource defaultSessionAttributes]];
}

- (id)initWithDataSource:(id)newDataSource andAttributes:(id)newAttributes {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    self = [super init];
    
    if (self) {
        self.dataSource     = newDataSource;
        self.attributes     = newAttributes;
        self.x_allItems     = [NSMutableArray array];
        
        if (dataSource) {
            // reload our data via notes + forwards from NubBucketManger
            [self.dataSource forwardItemsForObserver:self registerForUpdates:YES];
        }
    }
    
    return self;
}

- (void)setAttributes:(NSDictionary *)newAttributes {
    id staleAttributes = attributes;
    
    @synchronized(self) {
        attributes = newAttributes;
        
        NSArray *attrKeys = @[NubItemQueryAttribute,
                              NubItemImagesAttribute,
                              NubItemMoviesAttribute,
                              NubItemOthersAttribute,
                              NubItemArrangeByAttribute,
                              NubItemOrderByAttribute,
                              NubItemNameAttribute,
                              NubItemLimitAttribute,
                              NubItemCallbackAttribute
                              ];
        
        [attrKeys enumerateObjectsUsingBlock:^(id key, NSUInteger index, BOOL *stop) {
            [staleAttributes    removeObserver:self forKeyPath:key];
            [newAttributes      addObserver:self    forKeyPath:key options:NSKeyValueObservingOptionNew context:NULL];
        }];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    [self reloadData];
}

- (NSUInteger)itemsCount {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    return x_items.count;
}

- (NSUInteger)totalItemsCount {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    NSUInteger count = 0;
    
    @synchronized(x_allItems) {
        count = x_allItems.count;
    }
    
    return count;
}

// re-filter the data thru our attrs
// (DOES NOT reload the items from the bucketManager)
- (void)reloadData {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    // don't try to load if we aren't a full object yet
    if (!self.attributes.count) {
        return;
    }
    
    @synchronized(self) {
        self.x_items = [self x_transformItems:x_allItems];
    }
    
    [self x_noteNow];
}

- (NSArray *)items {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    if (!x_items) {
        [self reloadData];
    }
    
    return x_items;
}


#pragma bucketManager methods

- (void)addItems:(NSArray *)newItems {
    if (!newItems || !newItems.count) {
        return;
    }
    
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    NSIndexSet *regularSet = [newItems indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^(NubItem *item, NSUInteger idx, BOOL *stop) {
        if ([item isSystemItem]) {
            return NO;
        }
        
        return YES;
    }];
    
    NSArray *regularItems = [newItems objectsAtIndexes:regularSet];
    
    if (!regularItems || !regularItems.count) {
        return;
    }
    
    @synchronized(x_allItems) {
        [x_allItems addObjectsFromArray:regularItems];
    }
    
    [self reloadData];
}

- (void)removeItems:(NSArray *)items {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    if (!items) {
        return;
    }
    
    @synchronized(self) {
        [x_allItems removeObjectsInArray:items];
        x_items = [self x_transformItems:x_allItems];
    }
    
    [self x_noteNow];
}

- (void)dealloc {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    [attributes removeObserver:self forKeyPath:NubItemQueryAttribute context:NULL];
    [attributes removeObserver:self forKeyPath:NubItemImagesAttribute context:NULL];
    [attributes removeObserver:self forKeyPath:NubItemMoviesAttribute context:NULL];
    [attributes removeObserver:self forKeyPath:NubItemOthersAttribute context:NULL];
    [attributes removeObserver:self forKeyPath:NubItemArrangeByAttribute context:NULL];
    [attributes removeObserver:self forKeyPath:NubItemOrderByAttribute context:NULL];
    [attributes removeObserver:self forKeyPath:NubItemNameAttribute context:NULL];
    [attributes removeObserver:self forKeyPath:NubItemLimitAttribute context:NULL];
    [attributes removeObserver:self forKeyPath:NubItemCallbackAttribute context:NULL];
    
    // remove ourselv
    [self.dataSource removeObserver:self];
}


#pragma mark Private

- (NSArray *)x_transformItems:(NSMutableArray *)rawItems {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    
    if (!rawItems) {
        return [NSMutableArray array];
    }
    
    @synchronized(rawItems) {

        // setups
        NSUInteger      limitCount      = DEFAULT_SESSION_LIMIT;
        NSMutableArray  *activeItems    = [rawItems mutableCopy];
        
        // ensure a clean array to start with
        NSIndexSet *nullSet = [activeItems indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^(NubItem *item, NSUInteger idx, BOOL *stop) {
            if (item) {
                return NO;
            }
            return YES;
        }];
        [activeItems removeObjectsAtIndexes:nullSet];
        
        // Filter (images/movies/etc)
        NSMutableArray *wantedMediaKinds = [NSMutableArray array];
        
        if ([attributes[NubItemImagesAttribute] boolValue]) {
            [wantedMediaKinds addObject:@(NubItemMediaKindImage)];
        }
        if ([attributes[NubItemMoviesAttribute] boolValue]) {
            [wantedMediaKinds addObject:@(NubItemMediaKindMovie)];
        }
        if ([attributes[NubItemOthersAttribute] boolValue]) {
            [wantedMediaKinds addObject:@(NubItemMediaKindOther)];
        }
        
        NSString *query = attributes[NubItemQueryAttribute];
        
        NSPredicate *predicate = nil;
        
        if (query && ![query isEqualToString:@""]) {
            //predicate = [NSPredicate predicateWithFormat:@"mediaKind IN %@ AND (nubspace CONTAINS[cd] %@) OR (codes CONTAINS[cd] %@)", wantedMediaKinds, query, query];
            predicate = [NSPredicate predicateWithFormat:@"(nubspace CONTAINS[cd] %@) OR (codes CONTAINS[cd] %@)", query, query];
            
            @try {
                @synchronized(activeItems) {
                    [activeItems filterUsingPredicate:predicate];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"*** caught: %@", exception);
                
                NSBeep();
                
                return activeItems;
            }
        }
        
        // don't sort a nil array
        if (!activeItems.count) {
            return [NSMutableArray array];
        }

        
        // don't sort a nil array
        if (!activeItems.count) {
            return [NSMutableArray array];
        }
        
        // ArrangeBy
        NSComparisonResult (^arrangeBy)(id obj1, id obj2) = NULL;
        
        switch ([attributes[NubItemArrangeByAttribute] integerValue]) {
            case NubItemArrangeByName:
                arrangeBy = ^(NubItem *o1, NubItem *o2){ return [[[o1 nubspace] lowercaseString] compare:[[o2 nubspace] lowercaseString]]; };
                break;
                
            case NubItemArrangeBySize:
                arrangeBy = ^(NubItem *o1, NubItem *o2){ return [o1.size compare:o2.size]; };
                break;
                
            case NubItemArrangeByKind:
                arrangeBy = ^(NubItem *o1, NubItem *o2){ return [o1.kind compare:o2.kind]; };
                break;
                
            case NubItemArrangeByDateAdded:
                arrangeBy = ^(NubItem *o1, NubItem *o2){ return [o1.dateAdded compare:o2.dateAdded]; };
                break;
                
            case NubItemArrangeByDateOpened:
                arrangeBy = ^(NubItem *o1, NubItem *o2){ return [o1.dateOpened compare:o2.dateOpened]; };
                break;
                
            case NubItemArrangeByDateCreated:
                arrangeBy = ^(NubItem *o1, NubItem *o2){ return [o1.dateCreated compare:o2.dateCreated]; };
                break;
                
            case NubItemArrangeByDateModified:
                arrangeBy = ^(NubItem *o1, NubItem *o2){ return [o1.dateModified compare:o2.dateModified]; };
                break;
                
            case NubItemArrangeByOpenCount:
                arrangeBy = ^(NubItem *o1, NubItem *o2){ return [o1.openCount compare:o2.openCount]; };
                break;
                
            default: /* ie. show "favorites" by default NubItemArrangeByRating */
                arrangeBy = ^(NubItem *o1, NubItem *o2){
                    if (o1 == o2) { return NSOrderedSame; }
                    if (o1.rating == o2.rating) { return NSOrderedSame; }
                    
                    if (!o1) { return NSOrderedAscending; }
                    if (!o1.rating) { return NSOrderedAscending; }
                    
                    if (!o2) { return NSOrderedDescending; }
                    if (!o2.rating) { return NSOrderedDescending; }
                    
                    return [o1.rating compare:o2.rating];
                };
                break;
        }
        
        // arrange the array
        if (arrangeBy) {
            [activeItems sortWithOptions:NSSortConcurrent usingComparator:arrangeBy];
        }
        
        // OrderBy
        switch ([attributes[NubItemOrderByAttribute] integerValue]) {
            case NubItemOrderByDescending:
                activeItems = [[[activeItems reverseObjectEnumerator] allObjects] mutableCopy];
                
            default:
                break;
        }
        
        // LIMIT the items
        limitCount = [attributes[NubItemLimitAttribute] unsignedIntegerValue];
        
        if (limitCount == 0 || limitCount > activeItems.count) {
            limitCount = activeItems.count;
        }
        
        return [activeItems objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, limitCount)]];
    }
    
    // if for some reason we fail, return a dummy array
    return [NSArray array];
}

- (void)x_noteNow {
#ifdef DEBUG_CAVEMAN
    DebugLog();
#endif
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(x_noteNow) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:NubItemSourceDidUpdateNotification object:self]
                                               postingStyle:NSPostASAP
                                               coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                   forModes:nil];
}

@end