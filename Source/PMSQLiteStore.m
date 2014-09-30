//
//  PMSQLiteStore.m
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

#import "PMSQLiteStore.h"

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabasePool.h"
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"

#import "PMObjectID_Private.h"
#import "PMSQLiteObject_Private.h"

static NSString * const PMSQLiteStoreUpdateException = @"PMSQLiteStoreUpdateException";

#define UpdateException [NSException exceptionWithName:PMSQLiteStoreUpdateException reason:nil userInfo:nil]

@implementation PMSQLiteStore
{
    FMDatabaseQueue *_dbQueue;
    NSMutableDictionary *_dictionary;
    
    NSMutableSet *_insertedObjects;
    NSMutableSet *_deletedObjects;
    NSMutableSet *_updatedObjects;
}

- (id)initWithURL:(NSURL *)url
{
    self = [super initWithURL:url];
    if (self)
    {
        _dictionary = [NSMutableDictionary dictionary];
        
        _insertedObjects = [NSMutableSet set];
        _deletedObjects = [NSMutableSet set];
        _updatedObjects = [NSMutableSet set];
        
        if (url)
        {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]])
            {
                _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[url path]];
            }
            else
            {
                _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[url path]];
                [self pmd_createTables];
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [_dbQueue close];
}

#pragma mark Super Methods

- (id<PMPersistentObject>)persistentObjectWithObjectID:(PMObjectID*)objectID
{
    if (objectID.isTemporaryID)
        return nil;
    
    __block PMSQLiteObject *persistentObject = [_dictionary objectForKey:objectID.URIRepresentation];
    
    if (!persistentObject)
    {
        [_dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT Objects.id, Objects.type, Objects.updateDate, Data.data FROM Objects JOIN Data ON Objects.id = Data.id WHERE Objects.id = %ld", objectID.dbID];
            
            if ([resultSet next])
            {
                PMObjectID *objectID = [[PMObjectID alloc] initWithDbID:[resultSet intForColumnIndex:0]
                                                                   type:[resultSet stringForColumnIndex:1]
                                                        persistentStore:self];
                
                persistentObject = [[PMSQLiteObject alloc] initWithObjectID:objectID];
                persistentObject.lastUpdate = [NSDate dateWithTimeIntervalSince1970:[resultSet doubleForColumnIndex:2]];
                persistentObject.data = [resultSet dataForColumnIndex:3];
                
                persistentObject.persistentStore = self;
                
                [resultSet close];
            }
        }];
        
        if (persistentObject)
            [_dictionary setObject:persistentObject forKey:@(persistentObject.objectID.dbID)];
    }
    
    if (persistentObject)
        [self pmd_didAccessObjectWithID:persistentObject.objectID.dbID];
    
    return persistentObject;
}

- (NSArray*)persistentObjectsOfType:(NSString*)type
{
    if (type == nil)
    {
        NSString *reason = @"Cannot query for persistent objects with a nil type.";
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        [exception raise];
        return nil;
    }
    
    __block  NSMutableArray *array = nil;
    
    NSMutableArray *dbIDs = [NSMutableArray array];
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT Objects.id, Objects.type, Objects.updateDate, Data.data FROM Objects JOIN Data ON Objects.id = Data.id WHERE Objects.type = %@", type];
        
        array = [NSMutableArray array];
        
        while ([resultSet next])
        {
            PMObjectID *objectID = [[PMObjectID alloc] initWithDbID:[resultSet intForColumnIndex:0]
                                                               type:[resultSet stringForColumnIndex:1]
                                                    persistentStore:self];
            
            PMSQLiteObject *persistentObject = [[PMSQLiteObject alloc] initWithObjectID:objectID];
            persistentObject.lastUpdate = [NSDate dateWithTimeIntervalSince1970:[resultSet doubleForColumnIndex:2]];
            persistentObject.data = [resultSet dataForColumnIndex:3];
            
            persistentObject.persistentStore = self;
            
            [array addObject:persistentObject];
            [dbIDs addObject:@(persistentObject.objectID.dbID)];
        }
        
        [resultSet close];
    }];

    for (NSNumber *dbID in dbIDs)
        [self pmd_didAccessObjectWithID:dbID.integerValue];
    
    return array;
}

- (PMSQLiteObject*)createNewEmptyPersistentObjectWithType:(NSString*)type
{
    __block BOOL succeed = YES;
    __block PMSQLiteObject *persistentObject = nil;
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        @try
        {
            if (![db executeUpdate:@"INSERT INTO Objects (type, creationDate) values (?, ?)", type, @([[NSDate date] timeIntervalSince1970])])
                @throw UpdateException;
            
            sqlite_int64 dbID = db.lastInsertRowId;
            
            PMObjectID *objectID = [[PMObjectID alloc] initWithDbID:dbID type:type persistentStore:self];
            persistentObject = [[PMSQLiteObject alloc] initWithObjectID:objectID];
            
            if(![db executeUpdate:@"INSERT INTO Data (id) values (?)", @(dbID)])
                @throw UpdateException;
        }
        @catch (NSException *exception)
        {
            succeed = NO;
            
            if ([exception.name isEqualToString:PMSQLiteStoreUpdateException])
                *rollback = YES;
            else
                @throw exception;
        }
    }];
    
    return persistentObject;
}


- (void)deletePersistentObjectWithObjectID:(PMObjectID*)objectID
{
    PMSQLiteObject *object = [self persistentObjectWithObjectID:objectID];
    
    [_dictionary removeObjectForKey:@(objectID.dbID)];
    
    // If the object is queued to be inserted, remove from the queue.
    if ([_insertedObjects containsObject:object])
        [_insertedObjects removeObject:object];
    
    // If the object is queued to save changeds, remove form the queue and add to deleted objects list.
    else if ([_updatedObjects containsObject:object])
    {
        [_updatedObjects removeObject:object];
        [_deletedObjects addObject:object];
    }
    else
    {
        // If exists persistent object, add to deleted objects list
        if (object)
            [_deletedObjects addObject:object];
        
        // otherwise, there is nothing to do, the object is not stored in persistence.
    }
}

- (BOOL)deleteEntriesOfType:(NSString*)type olderThan:(NSDate*)date policy:(PMOptionDelete)option // <-- THIS METHOD SHOULD BE IN CONTEXT, NOT IN DB
{
    NSString *optionDate = nil;
    switch (option)
    {
        case PMOptionDeleteByAccessDate:
            optionDate = @"accessDate";
            break;

        case PMOptionDeleteByCreationDate:
            optionDate = @"creationDate";
            break;
            
        case PMOptionDeleteByUpdateDate:
            optionDate = @"updateDate";
            break;
    }
    
    NSString *query0 = nil;
    NSString *query1 = nil;
    NSString *query2 = nil;

    if (type && ! date)
    {
        query0 = [NSString stringWithFormat:@"SELECT Objects.id FROM Objects WHERE type = \"%@\"",type];
        query1 = [NSString stringWithFormat:@"DELETE FROM Data WHERE id IN (SELECT Objects.id FROM Objects WHERE type = \"%@\")",type];
        query2 = [NSString stringWithFormat:@"DELETE FROM Objects WHERE type = \"%@\"", type];
    }
    else if (!type && date)
    {
        query0 = [NSString stringWithFormat:@"SELECT Objects.id FROM Objects WHERE %@ < %f", optionDate, [date timeIntervalSince1970]];
        query1 = [NSString stringWithFormat:@"DELETE FROM Data WHERE id IN (SELECT Objects.id FROM Objects WHERE %@ < %f)",optionDate, [date timeIntervalSince1970]];
        query2 = [NSString stringWithFormat:@"DELETE FROM Objects WHERE %@ < %f",optionDate, [date timeIntervalSince1970]];
    }
    else if (type && date)
    {
        query0 = [NSString stringWithFormat:@"SELECT Objects.id FROM Objects WHERE type = \"%@\" AND %@ < %f)", type, optionDate, [date timeIntervalSince1970]];
        query1 = [NSString stringWithFormat:@"DELETE FROM Data WHERE id IN (SELECT Objects.id FROM Objects WHERE type = \"%@\" AND %@ < %f)", type, optionDate, [date timeIntervalSince1970]];
        query2 = [NSString stringWithFormat:@"DELETE FROM Objects WHERE type = \"%@\" AND %@ < %f",type, optionDate, [date timeIntervalSince1970]];
    }
    else //if (!type && !date)
    {
        query0 = @"SELECT Objects.id FROM Objects";
        query1 = @"DELETE FROM Data";
        query2 = @"DELETE FROM Objects";
    }
    
    __block BOOL succeed = YES;
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        @try
        {
            FMResultSet *resultSet = [db executeQuery:query0];
            
            NSMutableArray *keys = [NSMutableArray array];
            while ([resultSet next])
            {
                NSInteger dbID = [resultSet intForColumnIndex:0];
                [keys addObject:@(dbID)];
            }
            
            [resultSet close];
            
            if(![db executeUpdate:query1])
                @throw UpdateException;
            
            if (![db executeUpdate:query2])
                @throw UpdateException;
            
            // Once here, no exceptions happened!
            [_dictionary removeObjectsForKeys:keys];
        }
        @catch (NSException *exception)
        {
            succeed = NO;
            
            if ([exception.name isEqualToString:PMSQLiteStoreUpdateException])
                *rollback = YES;
            else
                @throw exception;
        }
    }];
    
    return succeed;
}

- (BOOL)save
{
    BOOL success = YES;
    
    @synchronized(self)
    {
        NSMutableSet *insertedObjects = [_insertedObjects copy];
        [_insertedObjects removeAllObjects];
        
        NSMutableSet *deletedObjects = [_deletedObjects copy];
        [_deletedObjects removeAllObjects];
        
        NSMutableSet *updatedObjects = [_updatedObjects copy];
        [_updatedObjects removeAllObjects];
        
        
        // -- Inserted Objects -- //
        for (PMSQLiteObject *object in insertedObjects)
        {
            BOOL flag = [self pmd_insertPersistentObject:object];
            success = success || flag;
        }
        
        // -- Deleted Objects -- //
        for (PMSQLiteObject *object in deletedObjects)
        {
            BOOL flag = [self pmd_deletePersistentObject:object];
            success = success || flag;
        }
        
        // -- Updated Objects -- //
        for (PMSQLiteObject *object in updatedObjects)
        {
            BOOL flag = [self pmd_updatePersistentObject:object];
            if (flag)
                [object pmd_setHasChanges:NO];
            success = success || flag;
        }
    }
    
    return success;
}

#pragma mark Public Methods

- (void)cleanCache
{
    [_dictionary removeAllObjects];
}

#pragma mark Private Methods

- (void)pmd_didChangePersistentObject:(PMSQLiteObject*)object
{
    if (object.objectID.isTemporaryID == NO)
        [_updatedObjects addObject:object];
}

- (BOOL)pmd_createTables
{
    __block BOOL succeed = YES;
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        @try
        {
            [db executeUpdate:@"DROP TABLE Objects"];
            [db executeUpdate:@"DROP TABLE Data"];
            [db executeUpdate:@"CREATE TABLE Objects (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, creationDate REAL, updateDate REAL, accessDate REAL)"]; // <-- MODIFIED THIS
            [db executeUpdate:@"CREATE TABLE Data (id INTEGER PRIMARY KEY, data BLOB, FOREIGN KEY(id) REFERENCES Objects(id))"];
        }
        @catch (NSException *exception)
        {
            succeed = NO;
            
            if ([exception.name isEqualToString:PMSQLiteStoreUpdateException])
                *rollback = YES;
            else
                @throw exception;
        }
    }];
    
    return succeed;
}

- (BOOL)pmd_insertPersistentObject:(PMSQLiteObject*)object
{
    __block BOOL succeed = YES;
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        @try
        {
            if (![db executeUpdate:@"INSERT INTO Objects (type, creationDate, updateDate, accessDate) values (?, ?, ?, ?, ?)",
                 object.objectID.type,
                 @([[NSDate date] timeIntervalSince1970]),
                 object.lastUpdate,
                 object.lastUpdate
                 ])
                @throw UpdateException;
            
            sqlite_int64 dbID = db.lastInsertRowId;
            object.objectID.dbID = (long)dbID;
            object.objectID.temporaryID = NO;
            
            if(![db executeUpdate:@"INSERT INTO Data (id, data) values (?, ?)", @(dbID), object.data])
                @throw UpdateException;
        }
        @catch (NSException *exception)
        {
            succeed = NO;
            
            if ([exception.name isEqualToString:PMSQLiteStoreUpdateException])
                *rollback = YES;
            else
                @throw exception;
        }        
    }];
    
    return succeed;
}

- (BOOL)pmd_updatePersistentObject:(PMSQLiteObject*)object
{
    NSAssert(object.objectID.isTemporaryID == NO, @"PersistentObject must have a non temprary object ID");
    
    __block BOOL succeed = YES;
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        @try
        {
            if (![db executeUpdate:@"UPDATE Objects SET updateDate = ? WHERE id = ?", object.lastUpdate, @(object.objectID.dbID)])
                @throw UpdateException;
            
            if(![db executeUpdate:@"UPDATE Data SET data = ? WHERE id = ?", object.data, @(object.objectID.dbID)])
                @throw UpdateException;
        }
        @catch (NSException *exception)
        {
            succeed = NO;
            
            if ([exception.name isEqualToString:PMSQLiteStoreUpdateException])
                *rollback = YES;
            else
                @throw exception;
        }
    }];
    
    return succeed;
}

- (BOOL)pmd_deletePersistentObject:(PMSQLiteObject*)object
{
    __block BOOL succeed = YES;
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        @try
        {
            if (![db executeUpdate:@"DELETE FROM Data WHERE id = ?", @(object.objectID.dbID)])
                @throw UpdateException;

            if (![db executeUpdate:@"DELETE FROM Objects WHERE id = ?", @(object.objectID.dbID)])
                @throw UpdateException;
        }
        @catch (NSException *exception)
        {
            succeed = NO;
            
            if ([exception.name isEqualToString:PMSQLiteStoreUpdateException])
                *rollback = YES;
            else
                @throw exception;
        }
    }];
    
    return succeed;
}

- (BOOL)pmd_didAccessObjectWithID:(NSInteger)dbID
{
    if (dbID == NSNotFound)
        return NO;
    
    __block BOOL succeed = YES;
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        @try
        {
            if(![db executeUpdate:@"UPDATE Objects SET accessDate = ? WHERE id = ?", @([[NSDate date] timeIntervalSince1970]), @(dbID)])
                @throw UpdateException;
        }
        @catch (NSException *exception)
        {
            succeed = NO;
            
            if ([exception.name isEqualToString:PMSQLiteStoreUpdateException])
                *rollback = YES;
            else
                @throw exception;
        }
    }];
    
    return succeed;
}

@end
