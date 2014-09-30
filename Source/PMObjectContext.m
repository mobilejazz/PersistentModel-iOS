//
//  PMObjectContext.m
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

#import "PMObjectContext.h"

#import "PMPersistentObject.h"
#import "PMPersistentStore.h"
#import "PMObjectID_Private.h"

#import "PMBaseObject_Private.h"

NSString * const PMObjectContextDidSaveNotification = @"PMObjectContextDidSaveNotification";
NSString * const PMObjectContextSavedObjectsKey = @"PMObjectContextSavedObjectsKey";
NSString * const PMObjectContextDeletedObjectsKey = @"PMObjectContextDeletedObjectsKey";

static NSInteger kContextIDCount = 0;

@implementation PMObjectContext
{
    NSMutableDictionary *_objects;
    NSMutableSet *_deletedObjects;
    BOOL _hasChanges;
    
    BOOL _isSaving;
    NSCondition *_savingCondition;
    NSInteger _savingOperationIndex;
    
    NSInteger _temporaryIDCount;
    NSInteger _contextID;
}

- (id)initWithPersistentStore:(PMPersistentStore *)persistentStore
{
    self = [super init];
    if (self)
    {
        _persistentStore = persistentStore;
        
        _hasChanges = NO;
        _isSaving = NO;
        _savingCondition = [[NSCondition alloc] init];
        _objects = [NSMutableDictionary dictionary];
        _deletedObjects = [NSMutableSet set];
        
        _temporaryIDCount = 0;
        _contextID = ++kContextIDCount;
        
    }
    return self;
}

#pragma mark Properties

- (BOOL)hasChanges
{
    if (_hasChanges)
        return YES;
    
    NSArray *allObjects = _objects.allValues;
    
    for (PMBaseObject *object in allObjects)
    {
        if (object.hasChanges)
            return YES;
    }
    
    return NO;
}

#pragma mark Public Methods

- (id)objectForObjectID:(PMObjectID*)objectID
{
    PMBaseObject* object = [_objects objectForKey:objectID.URIRepresentation];
    
    if (!object)
        object = [self pmd_baseObjectFromPersistentStoreWithObjectID:objectID];
    
    return object;
}

- (BOOL)containsObjectWithObjectID:(PMObjectID*)objectID
{
    return [_objects objectForKey:objectID.URIRepresentation] != nil;
}

- (NSArray*)registeredObjects
{
    return _objects.allValues;
}

- (BOOL)insertObject:(PMBaseObject*)object
{
    if (object == nil)
    {
        NSString *reason = @"You cannot insert a nil object into a context.";
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        [exception raise];
        return NO;
    }
    
    if (object.context != nil)
    {
        NSString *reason = @"You cannot insert an object to two contexts at same time.";
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        [exception raise];
        return NO;
    }
    
    if ([self containsObjectWithObjectID:object.objectID])
        return NO;
    
    if (object.objectID == nil)
    {
        NSInteger itemID = ++_temporaryIDCount;
        NSInteger temporaryID = [[NSString stringWithFormat:@"%ld00%ld",_contextID, itemID] integerValue];
        PMObjectID *objectID = [[PMObjectID alloc] initWithTempraryID:temporaryID type:NSStringFromClass(object.class)];
        object.objectID = objectID;
    }
    else
    {
        if (object.objectID.temporaryID == YES)
        {
            NSString *reason = @"You cannot insert a temporal object into a context.";
            NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
            [exception raise];
            return NO;
        }
        else if (object.objectID.persistentStore != _persistentStore)
        {
            NSString *reason = @"You cannot insert an object from a different persistent store.";
            NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
            [exception raise];
            return NO;
        }
    }
        
    _hasChanges = YES;
    
    object.context = self;
    [_objects setObject:object forKey:object.objectID.URIRepresentation];
    
    return YES;
}

- (void)deleteObject:(PMBaseObject*)object
{
    if (object == nil)
    {
        NSString *reason = @"You cannot delete a nil object from a context.";
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        [exception raise];
        return;
    }
    
    if ([_objects.allValues containsObject:object])
    {
        _hasChanges = YES;
        [_objects removeObjectForKey:object.objectID.URIRepresentation];
        [_deletedObjects addObject:object];
        object.context = nil;
    }
}

- (void)save
{
    [self saveWithCompletionBlock:NULL];
}

- (void)saveWithCompletionBlock:(void (^)(BOOL succeed))completionBlock
{
    void (^saveBlock)() = ^{
        _savingOperationIndex += 1;
        NSInteger currentOperationIndex = _savingOperationIndex;
        
        [_savingCondition lock];
        
        while (_isSaving)
            [_savingCondition wait];
        
        _isSaving = YES;
        
        BOOL shouldSaveCoreDataContext = _hasChanges;
        
        // -- SAVED OBJECTS -- //
        NSMutableSet *savedObjects = [NSMutableSet set];
        NSArray *allValues = [_objects.allValues copy];
        
        // Create final object ID for temporary ones
        for (PMBaseObject *object in allValues)
        {
            if (object.objectID.isTemporaryID)
            {
                shouldSaveCoreDataContext = YES;
                [self pmd_createPersistentModelObjectForBaseObject:object];
                object.hasChanges = YES;
                [savedObjects addObject:object];
            }
        }
        
        // Update persistent object data.
        for (PMBaseObject *object in allValues)
        {
            if (object.hasChanges)
            {
                shouldSaveCoreDataContext = YES;
                [self pmd_updatePersistentModelObjectOfBaseObject:object];
                object.hasChanges = NO;
                [savedObjects addObject:object];
            }
        }
        
        // -- DELETED OBJECTS -- //
        NSSet *deletedObjects = [_deletedObjects copy];
        shouldSaveCoreDataContext |= deletedObjects.count > 0;
        for (PMBaseObject *object in deletedObjects)
            [_persistentStore deletePersistentObjectWithID:object.objectID.dbID];
        
        BOOL succeed = NO;
        if (shouldSaveCoreDataContext)
            succeed = [_persistentStore save];
        
        if (succeed)
            [_deletedObjects removeAllObjects];
        
        _hasChanges = NO;
        
        _isSaving = NO;
        [_savingCondition signal];
        [_savingCondition unlock];
        
        if (completionBlock)
            completionBlock(succeed);
        
        if (currentOperationIndex == _savingOperationIndex)
        {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            
            if (savedObjects.count > 0)
                [dict setValuesForKeysWithDictionary:@{PMObjectContextSavedObjectsKey : savedObjects}];
            if (deletedObjects.count > 0)
                [dict setValuesForKeysWithDictionary:@{PMObjectContextDeletedObjectsKey : deletedObjects}];
            
            NSNotification *notification = [NSNotification notificationWithName:PMObjectContextDidSaveNotification
                                                                         object:self
                                                                       userInfo:dict];
            
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }
    };
    
    if ([NSThread isMainThread])
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            saveBlock();
        });
    }
    else
    {
        saveBlock();
    }
}

- (void)mergeChangesFromContextDidSaveNotification:(NSNotification*)notification
{
    PMObjectContext *savedContext = notification.object;
    
    // If it is the same context, nothing to do
    if (savedContext == self)
        return;
    
    // If both context doesn't share the same persistent store, nothing to do
    if (savedContext.persistentStore != _persistentStore && _persistentStore != nil)
        return;
    
//    // If both context doesn't share the same persistent store url, nothing to do
//    if (![[savedContext.persistentStore.url path] isEqualToString:[_persistentStore.url path]])
//        return;
    
    NSArray *savedObjects = [notification.userInfo valueForKey:PMObjectContextSavedObjectsKey];
    
    for (PMBaseObject *object in savedObjects)
    {
        PMBaseObject *myObject = [_objects objectForKey:object.objectID.URIRepresentation];
        
        if (myObject)
        {
            NSDictionary *keyedValues = [object dictionaryWithValuesForKeys:[object.class pmd_allPersistentPropertyNames]];
            
            [myObject setValuesForKeysWithDictionary:keyedValues];
            myObject.hasChanges = NO;
            myObject.lastUpdate = object.lastUpdate;
        }
    }
}

- (NSArray*)objectsOfClass:(Class)objectClass
{
    if (![objectClass isSubclassOfClass:PMBaseObject.class])
        return @[];
    
    NSArray *result = [_persistentStore persistentObjectsOfType:NSStringFromClass(objectClass)];
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (PMPersistentObject *mo in result)
    {
        PMBaseObject *baseObject = [_objects objectForKey:@(mo.dbID)];
        
        if (!baseObject)
        {
            baseObject = [self pmd_baseObjectFromModelObject:mo];
            baseObject.hasChanges = NO;
            [self insertObject:baseObject];
        }
        
        [array addObject:baseObject];
    }
    
    return array;
}

#pragma mark Private Methods

- (void)pmd_updatePersistentModelObjectOfBaseObject:(PMBaseObject*)baseObject
{
    NSAssert(baseObject.objectID.temporaryID == NO, @"Object cannot be temporary");
    
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeRootObject:baseObject];
    [archiver finishEncoding];
    
    PMPersistentObject *object = [_persistentStore persistentObjectWithID:baseObject.objectID.dbID];
    
    NSAssert(object != nil, @"Object should not be nil");
    
    if (object)
    {
        object.lastUpdate = baseObject.lastUpdate;
        object.data = data;
    }
}

- (void)pmd_createPersistentModelObjectForBaseObject:(PMBaseObject*)baseObject
{
    NSAssert(baseObject.objectID.temporaryID == YES, @"Object must be temporary");
    
    PMPersistentObject *persistentObject = [_persistentStore createNewEmptyPersistentObjectWithType:baseObject.objectID.type];
    
    [_objects removeObjectForKey:baseObject.objectID.URIRepresentation];
    baseObject.objectID.dbID = persistentObject.dbID;
    baseObject.objectID.temporaryID = NO;
    baseObject.objectID.persistentStore = _persistentStore;
    [_objects setObject:baseObject forKey:baseObject.objectID.URIRepresentation];
}

- (PMBaseObject*)pmd_baseObjectFromPersistentStoreWithObjectID:(PMObjectID*)objectID
{
    PMPersistentObject *object = [_persistentStore persistentObjectWithID:objectID.dbID];
    
    if (object)
    {
        PMBaseObject *baseObject = [self pmd_baseObjectFromModelObject:object];
        baseObject.hasChanges = NO;
        [self insertObject:baseObject];

        return baseObject;
    }
    
    return nil;
}

- (PMBaseObject*)pmd_baseObjectFromModelObject:(PMPersistentObject*)persistentObject
{    
    NSAssert(persistentObject != nil, @"Peristent object should not be nil");
    NSAssert(persistentObject.dbID != NSNotFound, @"Persistent object must have a database identifier");
    
    NSData *data = persistentObject.data;
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    PMBaseObject *baseObject = [unarchiver decodeObject];
    baseObject.objectID = [[PMObjectID alloc] initWithDbID:persistentObject.dbID type:persistentObject.type persistentStore:persistentObject.persistentStore];
    baseObject.lastUpdate = persistentObject.lastUpdate;
    
    return baseObject;
}

@end
