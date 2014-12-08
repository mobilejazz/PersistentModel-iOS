//
//  NSArray+PMBaseObject.h
//  PersistentModelTest
//
//  Created by Joan Martin on 08/12/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const PMDInvalidObjectException;

@interface NSArray (PMBaseObject)

/**
 * Add an index to the current objects conained in the array (keeping the order).
 * @param index The index to add.
 * @discussion All objects must be of class `PMBaseObject`, otherwise this method will thorw an exception.
 **/
- (void)pmd_addIndex:(NSString*)index;

/**
 * Remove an index from all objects on the array.
 * @param index The index to add.
 * @discussion All objects must be of class `PMBaseObject`, otherwise this method will thorw an exception.
 **/
- (void)pmd_removeIndex:(NSString*)index;

@end
