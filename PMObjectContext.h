//
//  PMObjectContext.h
//  Created by Joan Martin.
//  Take a look to my repos at http://github.com/vilanovi
//

#import <Foundation/Foundation.h>

@class PMBaseObject;
@class PMPersistentStore;

extern NSString * const PMObjectContextDidSaveNotification;
extern NSString * const PMObjectContextSavedObjectsKey;
extern NSString * const PMObjectContextDeletedObjectsKey;

/*!
 * TODO
 */
@interface PMObjectContext : NSObject

/*!
 * TODO
 */
- (id)initWithPersistentStore:(PMPersistentStore*)persistentStore;

/*!
 * TODO
 */
@property (nonatomic, strong, readonly) PMPersistentStore *persistentStore;

/*!
 * TODO
 */
@property (nonatomic, assign, readonly) BOOL hasChanges;

/*!
 * Returns the object for for the given identifier key.
 * @param key A unique key identifying the object.
 * @return The persistent instance associated to the given key.
 * @discussion The method returns the "living instance" of the object if already awaked, otherwase it awakes from the persistence layer the object and returns it. If the object has never been created, returns nil.
 */
- (PMBaseObject*)objectForKey:(NSString*)key;

/*!
 * Call this method to check the existence of an object for a given key in the current context (living instances).
 * @param key A unike key identifying the object.
 * @return YES if exists an object with the given key in the current context, otherwise NO.
 */
- (BOOL)containsObjectWithKey:(NSString*)key;

/*!
 * This method returns all living instances registered on that context.
 * @return An array with all living instances for the current context.
 */
- (NSArray*)registeredObjects;

/*!
 * TODO
 */
- (void)insertObject:(PMBaseObject*)object;

/*!
 * TODO
 */
- (void)deleteObject:(PMBaseObject*)object;

/*!
 * TODO
 */
- (void)save;

/*!
 * TODO
 */
- (void)saveWithCompletionBlock:(void (^)(BOOL succeed))completionBlock;

/*!
 * TODO
 */
- (void)mergeChangesFromContextDidSaveNotification:(NSNotification*)notification;

/*!
 * TODO
 */
- (NSArray*)objectsOfClass:(Class)objectClass;

@end
