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
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copiesœ
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
#import "PMObjectIndex.h"

#import "PMSQLiteObject_Private.h"

static NSString * const PMSQLiteStoreUpdateException = @"PMSQLiteStoreUpdateException";

#define UpdateException [NSException exceptionWithName:PMSQLiteStoreUpdateException reason:nil userInfo:nil]

@implementation PMSQLiteStore
{
    FMDatabaseQueue *_dbQueue;
    NSMutableDictionary *_dictionary;
    
    NSMutableSet *_deletedObjects;
    NSMutableSet *_updatedObjects;
}

- (id)initWithURL:(NSURL *)url
{
    self = [super initWithURL:url];
    if (self)
    {
        _dictionary = [NSMutableDictionary dictionary];
        
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

- (id)persistentObjectWithID:(NSInteger)dbID
{
    if (dbID == NSNotFound)
        return nil;
    
    __block PMSQLiteObject *persistentObject = [_dictionary objectForKey:@(dbID)];
    
    if (!persistentObject)
    {
        [_dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT Objects.id, Objects.type, Objects.updateDate, Data.data FROM Objects JOIN Data ON Objects.id = Data.id WHERE Objects.id = %ld", (long)dbID];
            
            if ([resultSet next])
            {
                persistentObject = [[PMSQLiteObject alloc] initWithID:[resultSet intForColumnIndex:0]
                                                                 type:[resultSet stringForColumnIndex:1]];
                
                persistentObject.lastUpdate = [NSDate dateWithTimeIntervalSince1970:[resultSet doubleForColumnIndex:2]];
                persistentObject.data = [resultSet dataForColumnIndex:3];
                
                persistentObject.persistentStore = self;
                
                [resultSet close];
            }
        }];
        
        if (persistentObject)
            [_dictionary setObject:persistentObject forKey:@(persistentObject.dbID)];
    }
    
    if (persistentObject)
        [self pmd_didAccessObjectWithID:persistentObject.dbID];
    
    return persistentObject;
}

//- (NSArray*)persistentObjectsOfType:(NSString*)type
//{
//    if (type == nil)
//    {
//        NSString *reason = @"Cannot query for persistent objects with a nil type.";
//        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
//        [exception raise];
//        return nil;
//    }
//    
//    __block  NSMutableArray *array = nil;
//    
//    NSMutableArray *dbIDs = [NSMutableArray array];
//    
//    [_dbQueue inDatabase:^(FMDatabase *db) {
//        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT Objects.id, Objects.type, Objects.updateDate, Data.data FROM Objects JOIN Data ON Objects.id = Data.id WHERE Objects.type = %@", type];
//        
//        array = [NSMutableArray array];
//        
//        while ([resultSet next])
//        {
//            PMSQLiteObject *persistentObject = [[PMSQLiteObject alloc] initWithID:[resultSet intForColumnIndex:0]
//                                                                             type:[resultSet stringForColumnIndex:1]];
//            
//            persistentObject.lastUpdate = [NSDate dateWithTimeIntervalSince1970:[resultSet doubleForColumnIndex:2]];
//            persistentObject.data = [resultSet dataForColumnIndex:3];
//            persistentObject.persistentStore = self;
//            
//            [array addObject:persistentObject];
//            [dbIDs addObject:@(persistentObject.dbID)];
//        }
//        
//        [resultSet close];
//    }];
//
//    for (NSNumber *dbID in dbIDs)
//        [self pmd_didAccessObjectWithID:dbID.integerValue];
//    
//    return array;
//}

- (NSArray*)persistentObjectsOfType:(NSString *)type index:(NSString*)index offset:(NSInteger)offset limit:(NSInteger)limit
{
    NSMutableString *query = [NSMutableString stringWithString:@"SELECT Objects.id, Objects.type, Objects.updateDate, Data.data FROM Objects JOIN Data ON objects.id = Data.id"];
    
    if (type != nil)
        [query appendFormat:@" WHERE Objects.type = \"%@\"", type];
    
    if (index != nil)
    {
        if (type != nil)
            [query appendFormat:@" AND"];
        else
            [query appendFormat:@" WHERE"];
        
        [query appendFormat:@" Objects.id IN (SELECT Indexes.id FROM Indexes WHERE Indexes.idx = \"%@\" ORDER BY Indexes.sort)", index];
    }
    
//    if (limit > 0)
//        [query appendFormat:@" LIMIT %ld", (long)limit];
//    
//    [query appendFormat:@" OFFSET %ld", (long)offset];
    
    __block  NSMutableArray *array = nil;
    
    NSMutableArray *dbIDs = [NSMutableArray array];
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:query];
        
        array = [NSMutableArray array];
        
        while ([resultSet next])
        {
            PMSQLiteObject *persistentObject = [[PMSQLiteObject alloc] initWithID:[resultSet intForColumnIndex:0]
                                                                             type:[resultSet stringForColumnIndex:1]];
            
            persistentObject.lastUpdate = [NSDate dateWithTimeIntervalSince1970:[resultSet doubleForColumnIndex:2]];
            persistentObject.data = [resultSet dataForColumnIndex:3];
            persistentObject.persistentStore = self;
            
            [array addObject:persistentObject];
            [dbIDs addObject:@(persistentObject.dbID)];
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
            
            persistentObject = [[PMSQLiteObject alloc] initWithID:dbID type:type];
            persistentObject.persistentStore = self;
            
            if (![db executeUpdate:@"INSERT INTO Data (id) values (?)", @(dbID)])
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


- (void)deletePersistentObjectWithID:(NSInteger)dbID
{
    PMSQLiteObject *object = (PMSQLiteObject*)[self persistentObjectWithID:dbID];
    
    [_dictionary removeObjectForKey:@(dbID)];
    
    // If the object is queued to be inserted, remove from the queue.
//    if ([_insertedObjects containsObject:object])
//        [_insertedObjects removeObject:object];
    
    // If the object is queued to save changeds, remove form the queue and add to deleted objects list.
    /*else*/
    if ([_updatedObjects containsObject:object])
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
    NSString *query3 = nil;

    if (type && ! date)
    {
        query0 = [NSString stringWithFormat:@"SELECT Objects.id FROM Objects WHERE type = \"%@\"", type];
        query1 = [NSString stringWithFormat:@"DELETE FROM Data WHERE id IN (SELECT Objects.id FROM Objects WHERE type = \"%@\")", type];
        query2 = [NSString stringWithFormat:@"DELETE FROM Indexes WHERE id IN (SELECT Objects.id FROM Objects WHERE type = \"%@\")", type];
        query3 = [NSString stringWithFormat:@"DELETE FROM Objects WHERE type = \"%@\"", type];
    }
    else if (!type && date)
    {
        query0 = [NSString stringWithFormat:@"SELECT Objects.id FROM Objects WHERE %@ < %f", optionDate, [date timeIntervalSince1970]];
        query1 = [NSString stringWithFormat:@"DELETE FROM Data WHERE id IN (SELECT Objects.id FROM Objects WHERE %@ < %f)", optionDate, [date timeIntervalSince1970]];
        query2 = [NSString stringWithFormat:@"DELETE FROM Indexes WHERE id IN (SELECT Objects.id FROM Objects WHERE %@ < %f)", optionDate, [date timeIntervalSince1970]];
        query3 = [NSString stringWithFormat:@"DELETE FROM Objects WHERE %@ < %f", optionDate, [date timeIntervalSince1970]];
    }
    else if (type && date)
    {
        query0 = [NSString stringWithFormat:@"SELECT Objects.id FROM Objects WHERE type = \"%@\" AND %@ < %f)", type, optionDate, [date timeIntervalSince1970]];
        query1 = [NSString stringWithFormat:@"DELETE FROM Data WHERE id IN (SELECT Objects.id FROM Objects WHERE type = \"%@\" AND %@ < %f)", type, optionDate, [date timeIntervalSince1970]];
        query2 = [NSString stringWithFormat:@"DELETE FROM Indexes WHERE id IN (SELECT Objects.id FROM Objects WHERE type = \"%@\" AND %@ < %f)", type, optionDate, [date timeIntervalSince1970]];
        query3 = [NSString stringWithFormat:@"DELETE FROM Objects WHERE type = \"%@\" AND %@ < %f",type, optionDate, [date timeIntervalSince1970]];
    }
    else //if (!type && !date)
    {
        query0 = @"SELECT Objects.id FROM Objects";
        query1 = @"DELETE FROM Data";
        query2 = @"DELETE FROM Indexes";
        query3 = @"DELETE FROM Objects";
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
            
            if (![db executeUpdate:query1])
                @throw UpdateException;
            
            if (![db executeUpdate:query2])
                @throw UpdateException;
            
            if (![db executeUpdate:query3])
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
//        NSMutableSet *insertedObjects = [_insertedObjects copy];
//        [_insertedObjects removeAllObjects];
        
        NSMutableSet *deletedObjects = [_deletedObjects copy];
        [_deletedObjects removeAllObjects];
        
        NSMutableSet *updatedObjects = [_updatedObjects copy];
        [_updatedObjects removeAllObjects];
        
        
        // -- Inserted Objects -- //
//        for (PMSQLiteObject *object in insertedObjects)
//        {
//            BOOL flag = [self pmd_insertPersistentObject:object];
//            success = success || flag;
//        }
        
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

- (BOOL)addIndex:(PMObjectIndex*)objectIndex toObjectWithID:(NSInteger)dbID
{
    __block BOOL succeed = YES;
//    
//    [_dbQueue inDatabase:^(FMDatabase *db) {
//        [db executeQueryWithFormat:@""];
//    }];
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        @try
        {
            if (![db executeUpdate:@"INSERT INTO Indexes (id, idx, sort) values (?, ?, ?)", @(dbID), objectIndex.index, @(objectIndex.order)])
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

//- (BOOL)updateIndex:(PMObjectIndex*)objectIndex toObjectWithID:(NSInteger)dbID
//{
//    __block BOOL succeed = YES;
//    
//    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
//        @try
//        {
//            if (![db executeUpdateWithFormat:@"UPDATE Indexes SET order = %ld WHERE id = %ld AND index = %@", (long)objectIndex.order, (long)dbID, objectIndex.index])
//                @throw UpdateException;
//        }
//        @catch (NSException *exception)
//        {
//            succeed = NO;
//            
//            if ([exception.name isEqualToString:PMSQLiteStoreUpdateException])
//                *rollback = YES;
//            else
//                @throw exception;
//        }
//    }];
//    
//    return succeed;
//}

- (BOOL)deleteIndex:(NSString*)index toObjectWithID:(NSInteger)dbID
{
    NSString *query = nil;
    
    if (index && dbID != NSNotFound)
        query = [NSString stringWithFormat:@"DELETE FROM Indexes WHERE idx = \"%@\" AND id = %ld", index, (long)dbID];
    else if (index)
        query = [NSString stringWithFormat:@"DELETE FROM Indexes WHERE idx = \"%@\"", index];
    else if (dbID != NSNotFound)
        query = [NSString stringWithFormat:@"DELETE FROM Indexes WHERE id = %ld", (long)dbID];
    else
        query = [NSString stringWithFormat:@"DELETE FROM Indexes"];
    
    __block BOOL succeed = YES;
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        @try
        {
            if (![db executeUpdate:query])
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


- (NSArray*)indexesForObjectWithID:(NSInteger)dbID
{
    NSMutableArray *array = [NSMutableArray array];
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT Indexes.idx, Indexes.sort FROM Indexes WHERE Indexes.id = %ld", (long)dbID];
        
        while ([resultSet next])
        {
            PMObjectIndex *objectIndex = [[PMObjectIndex alloc] initWithIndex:[resultSet stringForColumnIndex:0]
                                                                        order:[resultSet intForColumnIndex:1]];
            
            [array addObject:objectIndex];
        }
        
        [resultSet close];
    }];
    
    return [array copy];
}

#pragma mark Public Methods

- (void)cleanCache
{
    [_dictionary removeAllObjects];
}

#pragma mark Private Methods

- (void)pmd_didChangePersistentObject:(PMSQLiteObject*)object
{
    if (object.dbID != NSNotFound)
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
            [db executeUpdate:@"DROP TABLE Indexes"];
            [db executeUpdate:@"CREATE TABLE Objects (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, creationDate REAL, updateDate REAL, accessDate REAL)"];
            [db executeUpdate:@"CREATE TABLE Data (id INTEGER PRIMARY KEY, data BLOB, FOREIGN KEY(id) REFERENCES Objects(id))"];
            [db executeUpdate:@"CREATE TABLE Indexes (id INTEGER NOT NULL, sort INTEGER DEFAULT 0, idx TEXT NOT NULL, FOREIGN KEY(id) REFERENCES Objects(id), PRIMARY KEY (id, idx))"];
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
                 object.type,
                 @([[NSDate date] timeIntervalSince1970]),
                 object.lastUpdate,
                 object.lastUpdate
                 ])
                @throw UpdateException;
            
            sqlite_int64 dbID = db.lastInsertRowId;
            object.dbID = (long)dbID;
            
            if (![db executeUpdate:@"INSERT INTO Data (id, data) values (?, ?)", dbID, object.data])
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
    NSAssert(object.dbID != NSNotFound, @"PersistentObject must have a database ID");
    
    __block BOOL succeed = YES;
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        @try
        {
            if (object.lastUpdate != nil)
            {
                if (![db executeUpdate:@"UPDATE Objects SET updateDate = ? WHERE id = ?", object.lastUpdate, @(object.dbID)])
                    @throw UpdateException;
            }
            
            if (![db executeUpdate:@"UPDATE Data SET data = ? WHERE id = ?", object.data, @(object.dbID)])
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
            if (![db executeUpdate:@"DELETE FROM Indexes WHERE id = ?", @(object.dbID)])
                @throw UpdateException;
            
            if (![db executeUpdate:@"DELETE FROM Data WHERE id = ?", @(object.dbID)])
                @throw UpdateException;

            if (![db executeUpdate:@"DELETE FROM Objects WHERE id = ?", @(object.dbID)])
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
            if (![db executeUpdate:@"UPDATE Objects SET accessDate = ? WHERE id = ?", @([[NSDate date] timeIntervalSince1970]), @(dbID)])
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
