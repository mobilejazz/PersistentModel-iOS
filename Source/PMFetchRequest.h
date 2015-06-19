//
//  PMFetchRequest.h
//  PersistentModel
//
//  Created by Joan Martin on 06/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PMPersistentStore.h"

/**
 * This class is used to setup a fetch query to the object context.
 **/
@interface PMFetchRequest : NSObject

/**
 * Fetch request to retrieve all objects of a specific class.
 * @param objectClass The class
 * @return A new fetch request ready to be used.
 **/
+ (PMFetchRequest*)fetchRequestWithClass:(Class)objectClass;

/**
 * Fetch request to retrieve all objects of a specific class for a given index.
 * @param objectClass The class
 * @param index The index of the objects
 * @return A new fetch request ready to be used.
 **/
+ (PMFetchRequest*)fetchRequestWithClass:(Class)objectClass index:(NSString*)index;

/**
 * The class type to fetch. Can be nil.
 * @discussion If nil, the query
 **/
@property (nonatomic, strong) Class objectClass;

/**
 * The index to be queried. Can be nil.
 **/
@property (nonatomic, strong) NSString *index;

/**
 * Maximum amount of entries to be retrieved. Default value is 0.
 * @discussion Use value 0 to fetch all entries.
 **/
@property (nonatomic, assign) NSInteger fetchLimit;

/**
 * Offset for the set of entries to be retrieved. Default value is 0.
 **/
@property (nonatomic, assign) NSInteger fetchOffset;

/**
 * The order of the fetch request.
 **/
@property (nonatomic, assign) PMOrderBy orderBy;

/**
 * If YES, the results will be returned ordered ascending, otherwise if NO, descending.
 **/
@property (nonatomic, assign) BOOL orderByAscending;

@end
