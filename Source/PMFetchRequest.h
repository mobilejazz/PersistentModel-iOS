//
//  PMFetchRequest.h
//  PersistentModelTest
//
//  Created by Joan Martin on 06/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMFetchRequest : NSObject

+ (PMFetchRequest*)fetchRequestWithClass:(Class)objectClass;
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

@end
