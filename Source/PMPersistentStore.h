//
//  PMPersistentStore.h
//  Created by Joan Martin.
//  Take a look to my repos at http://github.com/vilanovi
//
// Copyright (c) 2013 Joan Martin, vilanovi@gmail.com.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

#import <Foundation/Foundation.h>

@class PMPersistentObject;
@class PMObjectIndex;

/**
 * Multiples deleting options.
 **/
typedef enum __PMOptionDelete
{
    /**
     * Delete by comparing creation date.
     **/
    PMOptionDeleteByCreationDate,
    
    /**
     * Delete by comparing access date.
     **/
    PMOptionDeleteByAccessDate,
    
    /**
     * Delete by comparing updating date.
     **/
    PMOptionDeleteByUpdateDate
} PMOptionDelete;


/**
 * This value is used as Key in NSException and NSNotifications userInfo dictionary.
 **/
extern NSString * const PMPersistentStoreObjectKey;

/**
 * This is an abstract class that encapsulates the main functionalities for the persistent store.
 * Subclasses may override all methods and implement them following the specifications.
 **/
@interface PMPersistentStore : NSObject

/** ---------------------------------------------------------------- **
 *  @name Creating instances and initializing
 ** ---------------------------------------------------------------- **/

/**
 * Default initializer.
 * @param url The url of the persistent store. Cannot be nil.
 * @return The initialized instance.
 **/
- (id)initWithURL:(NSURL*)url;

/**
 * The url of the persistent store.
 **/
@property (nonatomic, strong, readonly) NSURL *url;

/** ---------------------------------------------------------------- **
 *  @name Fetching objects
 ** ---------------------------------------------------------------- **/

/**
 * This method should retrieve from the store the object with the given ID identifier. If the object is not found in the store, return nil.
 * @param dbID The model object identifier.
 * @return The associated persistent object or nil.
 **/
- (PMPersistentObject*)persistentObjectWithID:(NSInteger)dbID;

/**
 * This method queries all stored objects for the given type.
 * @param type The model object type. Cannot be nil.
 * @return An array with all stored objects of the given type.
 **/
- (NSArray*)persistentObjectsOfType:(NSString *)type index:(NSString*)index offset:(NSInteger)offset limit:(NSInteger)limit;

/** ---------------------------------------------------------------- **
 *  @name Object life-cycle
 ** ---------------------------------------------------------------- **/

/**
 * Creates a new persistent object and returns it for a model object key and type.
 * @param type The model object type. Cannot be nil.
 * @return The empty persistent object.
 * @discussion If already exists an object with the given key, this method raises a NSInvalidArgumentException exception with the existent object in the userInfo exception field (accessible via the key `PMPersistentStoreObjectKey`).
 **/
- (PMPersistentObject*)createNewEmptyPersistentObjectWithType:(NSString*)type;

/**
 * Removes a persistent object from the store.
 * @param key The model object identifier. Cannot be nil.
 * @discussion In order to persist changes it is needed to call the method `save`.
 **/
- (void)deletePersistentObjectWithID:(NSInteger)dbID;

/**
 * Removes all persistent objects for the given type, date and policy.
 * @param type The model object type. If nil, type is ignored.
 * @param date This is a time offset to query object into the store.
 * @param option Deleting policy can be by creation date, access date or update date.
 * @return YES if the deletion is successful, otherwise NO.
 * @discussion This method might operate direclty on the storage without need of performing posterior `save` of the current persistent store.
 **/
- (BOOL)deleteEntriesOfType:(NSString*)type olderThan:(NSDate*)date policy:(PMOptionDelete)option;

/** ---------------------------------------------------------------- **
 *  @name Saving changes
 ** ---------------------------------------------------------------- **/

/**
 * Call this method to persist changes of modifyied PMPersistentObjects.
 * @return YES if saved successfully, NO otherwise.
 * @discussion This method is executed in the current thread. A NO value as return indicates that the saving is not successful, not that the saving is not performed. This means that part of the persistent model could be saved, part not.
 **/
- (BOOL)save;

/** ---------------------------------------------------------------- **
 *  @name Indexing objects
 ** ---------------------------------------------------------------- **/

- (BOOL)addIndex:(PMObjectIndex*)objectIndex toObjectWithID:(NSInteger)dbID;
- (BOOL)deleteIndex:(NSString*)index toObjectWithID:(NSInteger)dbID;

- (NSArray*)indexesForObjectWithID:(NSInteger)dbID;

@end
