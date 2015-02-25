//
//  PMObjectContext.h
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

#import "PMFetchRequest.h"

@class PMBaseObject;
@class PMPersistentStore;
@class PMObjectID;
@class PMFetchRequest;

/**
 * After a successful save, this notification is posted.
 * UserInfo will contain the keys 'PMObjectContextSavedObjectsKey' and 'PMObjectContextDeletedObjectsKey' to retrieve the saved and deleted objects respectively.
 **/
extern NSString * const PMObjectContextDidSaveNotification;

/**
 * Key to be used in the UserInfo dictionary of the 'PMObjectContextDidSaveNotification' notification to retrieve the saved objects.
 **/
extern NSString * const PMObjectContextSavedObjectsKey;

/**
 * @const PMObjectContextDeletedObjectsKey Key to be used in the UserInfo dictionary of the 'PMObjectContextDidSaveNotification' notification to retrieve the deleted objects.
 **/
extern NSString * const PMObjectContextDeletedObjectsKey;

/**
 * An instance of PMObjectContext represents a single “object space” or scratch pad in an application. Its primary responsibility is to manage a collection of objects. These objects form a group of related model objects that represent an internally consistent view of one or more persistent stores. A single managed object instance exists in one and only one context, but multiple copies of an object can exist in different contexts. Thus object uniquing is scoped to a particular context.
 **/
@interface PMObjectContext : NSObject


/** ---------------------------------------------------------------- **
 *  @name Creating instances and initializing
 ** ---------------------------------------------------------------- **/

/**
 * Default initializer. 
 * @param persistentStore The persistent store to use. If nil any peristent store will be used and model won't be able to persist.
 **/
- (id)initWithPersistentStore:(PMPersistentStore*)persistentStore;

/** ---------------------------------------------------------------- **
 *  @name Registering and Fetching Objects
 ** ---------------------------------------------------------------- **/

/**
 * Returns an array of objects that meet the criteria specified by a given fetch request.
 * @param request A fetch request that specifies the search criteria for the fetch.
 * @param error If there is a problem executing the fetch, upon return contains an instance of NSError that describes the problem.
 * @return An array of objects that meet the criteria specified by request fetched from the receiver and from the persistent store. If an error occurs, returns nil. If no objects match the criteria specified by request, returns an empty array.
 **/
- (NSArray*)executeFecthRequest:(PMFetchRequest*)request error:(out NSError *__autoreleasing *)error;

/**
 * Queries to the persistent store and returns all objects stored of the given class.
 * @param objectClass The class to retrieve all stored objects.
 * @return An array with all instances of the specified class.
 **/
- (NSArray*)objectsOfClass:(Class)objectClass;

/**
 * Returns the object for for the given ID, if registered in the context.
 * @param objectID The ID of the object.
 * @return The instance associated to the given ID.
 **/
- (id)objectRegisteredForID:(PMObjectID*)objectID;

/**
 * Returns the object for for the given ID.
 * @param objectID The ID of the object.
 * @return The instance associated to the given ID.
 * @discussion The method returns the "living instance" of the object if already awaked, otherwase it awakes from the persistence store the object and returns it.
 **/
- (id)objectWithID:(PMObjectID*)objectID;

/**
 * This method returns all living instances registered on that context.
 * @return An array with all living instances for the current context.
 **/
- (NSArray*)registeredObjects;

/**
 * This method returns all instances that have been delted from that context.
 * @return An array with all deleted instances from the current context.
 **/
- (NSArray*)deletedObjects;

/** ---------------------------------------------------------------- **
 *  @name Object Management
 ** ---------------------------------------------------------------- **/

/**
 * Use this method to insert unregistered 'PMBaseObject's into the current context.
 * @param object The object to insert. This argument cannot be nil, otherwise a 'NSInvalidArgumentException' exception will be rised.
 * @return YES if the object has beeen inserted, NO otherwise.
 * @discussion If there is another object in the context with the same key, the given object won't be inserted into the context and the method will return NO. To persist changes a 'save' is required
 **/
- (BOOL)insertObject:(PMBaseObject*)object;

/**
 * Use this method to delete a registered object from the context.
 * @param object The object to delete.
 * @discussion This method will unregister the object from the context by setting the object.context to nil and stop tracking changes of it. To persist changes a 'save' is required.
 **/
- (void)deleteObject:(PMBaseObject*)object;

/** ---------------------------------------------------------------- **
 *  @name Saving
 ** ---------------------------------------------------------------- **/

/**
 * Boolean indicating if there are changes to save or not. YES if any new object has been inserted, deleted or modifyed, otherwise NO
 * @discussion This property works withing the 'hasChanges' property of 'PMBaseObject'. Remember that in 'PMBaseObject' changes are tracked via KVC methods. If you modify an object directly is your responsibility to set the flag 'hasChanges' to YES.
 **/
@property (nonatomic, assign, readonly) BOOL hasChanges;

/**
 * Saves the current context into the persistent store. This method is equivalent to '-saveWithCompletionBlock:' with a NULL block as argument.
 **/
- (void)save;

/**
 * Saves the current context into the persistent store. 
 * @param completionBlock This block is called once the save is finished and contains a parameter 'succeed' to check if the saving has been successful.
 * @discussion This method operates in a background thread (even calling the completion block).
 **/
- (void)saveWithCompletionBlock:(void (^)(BOOL succeed))completionBlock;

/**
 * A parent context. Default value is nil.
 * @discussion If not nil, after the current saves all changes are reflected to the parent context.
 **/
@property (nonatomic, weak) PMObjectContext *parentContext;

/** ---------------------------------------------------------------- **
 *  @name Managing Concurrency
 ** ---------------------------------------------------------------- **/

/**
 * Merges the changes specified in a given notification.
 * @param An instance of an `PMObjectContextDidSaveNotification` notification posted by another context.
 * @discussion If you want your context to react to this notification, you must manually register your context to observe the notification.
 **/
- (void)mergeChangesFromContextDidSaveNotification:(NSNotification*)notification;

/** ---------------------------------------------------------------- **
 *  @name Managing the Persistent Store
 ** ---------------------------------------------------------------- **/

/**
 * The current used persistent store.
 **/
@property (nonatomic, strong, readonly) PMPersistentStore *persistentStore;

@end
