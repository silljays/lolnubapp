//
//  NubItemSource.h
//  lolnub
//
//  Created by Me on 10/13/13.
//  Copyright (c) 2014 lolnub.com developers All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NubItem.h"

extern NSString *const NubItemSourceDidUpdateNotification;

extern NSString *const NubItemDefaultAttribute;
extern NSString *const NubItemNameAttribute;
extern NSString *const NubItemQueryAttribute;
extern NSString *const NubItemImagesAttribute;
extern NSString *const NubItemMoviesAttribute;
extern NSString *const NubItemOthersAttribute;
extern NSString *const NubItemArrangeByAttribute;
extern NSString *const NubItemOrderByAttribute;
extern NSString *const NubItemLimitAttribute;
extern NSString *const NubItemCallbackAttribute;

enum {
    NubItemArrangeByNone             = 0,
    NubItemArrangeByName             = 3,
    NubItemArrangeBySize             = 4,
    NubItemArrangeByKind             = 5,
    NubItemArrangeByDateAdded        = 6,
    NubItemArrangeByDateOpened       = 7,
    NubItemArrangeByDateCreated      = 8,
    NubItemArrangeByDateModified     = 9,
    NubItemArrangeByOpenCount        = 10,
    NubItemArrangeByRating           = 11,
    
};
typedef NSInteger NubItemArrangeBySetting;

enum {
    NubItemOrderByNone                     = 0,
    NubItemOrderByAscending                = 1,
    NubItemOrderByDescending               = 2
};
typedef NSInteger NubItemOrderBy;


@interface NubItemSource : NSObject

@property (weak)                id                  dataSource;
@property (strong, nonatomic)   NSDictionary        *attributes;


+ (NSMutableDictionary *)defaultSessionAttributes;

- (id)initWithDataSource:(id)newDataSource;
- (id)initWithDataSource:(id)newDataSource andAttributes:(id)newAttributes;

- (void)reloadData;

// a direct item count that doesn't copy the private items array
- (NSArray *)items;
- (NSUInteger)itemsCount;
- (NSUInteger)totalItemsCount;


// @protocol NubObserver

- (void)addItems:(NSArray *)items;
- (void)removeItems:(NSArray *)items;

@end
