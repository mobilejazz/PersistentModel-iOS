//
//  PMBaseObject.m
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

#import "PMBaseObject.h"

#import "PMBaseObject_Private.h"
#import "PMObjectID_Private.h"
#import "PMObjectContext_Private.h"

#import "PMObjectIndex.h"


NSString * const PMBaseObjectNilKeyException = @"PMBaseObjectNilKeyException";

static NSString* stringFromClass(Class theClass)
{
    static NSMapTable *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];
    });
    
    NSString *string = [map objectForKey:theClass];
    
    if (!string)
    {
        string = NSStringFromClass(theClass);
        [map setObject:string forKey:theClass];
    }
    
    return string;
}

@implementation PMBaseObject

- (id)init
{
    return [self initAndInsertToContext:nil];
}

- (id)initAndInsertToContext:(PMObjectContext*)context;
{
    self = [super init];
    if (self)
    {
        _objectID = nil;
        _hasChanges = NO;
        
        _insertedIndexes = @[];
        _deletedIndexes = @[];
        _indexes = nil;
        
        [context insertObject:self];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        _insertedIndexes = @[];
        _deletedIndexes = @[];
        _indexes = nil;
        
        NSArray *persistentKeys = [self.class pmd_allPersistentPropertyNames];
        for (NSString *key in persistentKeys)
        {
            id value = [aDecoder decodeObjectForKey:key];
            if (value)
                [self setValue:value forKey:key];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{    
    NSArray *persistentKeys = [self.class pmd_allPersistentPropertyNames];
    
    for (NSString *key in persistentKeys)
        [aCoder encodeObject:[self valueForKey:key] forKey:key];
}

//- (id)copyWithZone:(NSZone *)zone
//{
//    NSMutableData *data = [NSMutableData data];
//    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
//    [archiver encodeRootObject:self];
//    [archiver finishEncoding];
//    
//    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
//    PMBaseObject *copy = [unarchiver decodeObject];
//    
//    return copy;
//}

#pragma mark Key Value Coding

- (void)setValue:(id)value forKey:(NSString *)key
{
    NSArray *persistentKeys = [self.class pmd_allPersistentPropertyNames];
    
    if ([persistentKeys containsObject:key])
        _hasChanges = YES;
    
    [super setValue:value forKey:key];
}

#pragma mark Properties

- (void)setLastUpdate:(NSDate *)lastUpdate
{
    _lastUpdate = lastUpdate;
    _hasChanges = YES;
}

- (NSArray*)indexes
{
    if (!_indexes)
        _indexes = [self.context pmd_fetchIndexesForObjectWithID:self.objectID];
    
    return _indexes;
}

#pragma mark Private Methods

+ (NSArray*)pmd_allPersistentPropertyNames
{
    static NSMutableDictionary *persistentProperties = nil;
    
    static dispatch_once_t onceToken1;
    dispatch_once(&onceToken1, ^{
        persistentProperties = [NSMutableDictionary dictionary];
    });
    
    NSString *className = stringFromClass(self);
    NSArray *propertyNames = persistentProperties[className];
    
    if (!propertyNames)
    {
        Class superClass = [self superclass];
        
        NSMutableArray *array = nil;
        
        if ([superClass isSubclassOfClass:PMBaseObject.class])
            array = [[superClass pmd_allPersistentPropertyNames] mutableCopy];
        else
            array = [NSMutableArray array];
        
        [array addObjectsFromArray:[self pmd_persistentPropertyNames]];
        
        propertyNames = [array copy];
        persistentProperties[className] = propertyNames;
    }
    
    return propertyNames;
}

- (void)addIndex:(NSString*)index
{
    [self addIndex:index order:0];
}

- (void)addIndex:(NSString*)index order:(NSInteger)order
{
    __block BOOL exists = NO;
    
    [self.indexes enumerateObjectsUsingBlock:^(PMObjectIndex *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.index isEqualToString:index])
        {
            exists = YES;
            *stop = YES;
        }
    }];
    
    if (!exists)
    {
        PMObjectIndex *objectIndex = [[PMObjectIndex alloc] initWithIndex:index order:order];
        self.insertedIndexes = [self.insertedIndexes arrayByAddingObject:objectIndex];
        [self.context pmd_didRegisterIndex:objectIndex object:self];
        _hasChanges = YES;
    }
}

- (void)removeIndex:(NSString*)index
{
    __block PMObjectIndex *objIndex = nil;
    
    // Removing index from insertedIndexes
    __block NSMutableArray *insertedIndexes = nil;
    [self.insertedIndexes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PMObjectIndex *objectIndex, NSUInteger idx, BOOL *stop) {
        if ([objectIndex.index isEqualToString:index])
        {
            if (!insertedIndexes)
                insertedIndexes = [self.insertedIndexes mutableCopy];
            
            objIndex = objectIndex;
            [insertedIndexes removeObjectAtIndex:idx];
        }
    }];
    
    if (insertedIndexes)
        self.insertedIndexes = [insertedIndexes copy];
    
    // Removing index from indexes
    __block NSMutableArray *deletedIndexes = nil;
    __block NSMutableArray *indexes = nil;
    [self.indexes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PMObjectIndex *objectIndex, NSUInteger idx, BOOL *stop) {
        if ([objectIndex.index isEqualToString:index])
        {
            _hasChanges = YES;
            
            if (!indexes)
                indexes = [self.indexes mutableCopy];
            
            if (!deletedIndexes)
                deletedIndexes = [self.deletedIndexes mutableCopy];
            
            objIndex = objectIndex;
            [deletedIndexes addObject:objectIndex];
            [indexes removeObjectAtIndex:idx];
        }
    }];
    
    if (indexes)
        self.indexes = [indexes copy];
    
    if (deletedIndexes)
        self.deletedIndexes = [deletedIndexes copy];
    
    if (objIndex)
        [self.context pmd_didDeleteIndex:objIndex object:self];
}

- (NSArray*)allIndexes
{
    NSMutableArray *array = [NSMutableArray array];
    
    [self.insertedIndexes enumerateObjectsUsingBlock:^(PMObjectIndex *obj, NSUInteger idx, BOOL *stop) {
        [array addObject:obj.index];
    }];
    
    [self.indexes enumerateObjectsUsingBlock:^(PMObjectIndex *obj, NSUInteger idx, BOOL *stop) {
        [array addObject:obj.index];
    }];
    
    return [array copy];
}

@end


@implementation PMBaseObject (Subclassing)

+ (NSArray*)pmd_persistentPropertyNames
{
    // Subclasses may override
    return @[];
}

@end

#pragma mark - Extensions

NSString * const PMInvalidObjectException = @"PMInvalidObjectException";

@implementation NSArray (PMBaseObject)

- (void)pmd_makeObjectsAddIndex:(NSString*)index
{
    [self enumerateObjectsUsingBlock:^(PMBaseObject *obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:PMBaseObject.class])
        {
            [obj addIndex:index order:idx];
        }
        else
        {
            NSException *exception = [NSException exceptionWithName:PMInvalidObjectException
                                                             reason:[NSString stringWithFormat:@"You cannot add an index to an object of class %@", obj.class]
                                                           userInfo:nil];
            
            [exception raise];
        }
    }];
}

- (void)pmd_makeObjectsRemoveIndex:(NSString*)index
{
    [self enumerateObjectsUsingBlock:^(PMBaseObject *obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:PMBaseObject.class])
        {
            [obj removeIndex:index];
        }
        else
        {
            NSException *exception = [NSException exceptionWithName:PMInvalidObjectException
                                                             reason:[NSString stringWithFormat:@"You cannot remove an index to an object of class %@", obj.class]
                                                           userInfo:nil];
            
            [exception raise];
        }
    }];
}

@end

@implementation NSSet (PMBaseObject)

- (void)pmd_makeObjectsAddIndex:(NSString*)index
{
    [self enumerateObjectsUsingBlock:^(PMBaseObject *obj, BOOL *stop) {
        
        if ([obj isKindOfClass:PMBaseObject.class])
        {
            [obj addIndex:index];
        }
        else
        {
            NSException *exception = [NSException exceptionWithName:PMInvalidObjectException
                                                             reason:[NSString stringWithFormat:@"You cannot add an index to an object of class %@", obj.class]
                                                           userInfo:nil];
            
            [exception raise];
        }
    }];
}

- (void)pmd_makeObjectsRemoveIndex:(NSString*)index
{
    [self enumerateObjectsUsingBlock:^(PMBaseObject *obj, BOOL *stop) {
        
        if ([obj isKindOfClass:PMBaseObject.class])
        {
            [obj removeIndex:index];
        }
        else
        {
            NSException *exception = [NSException exceptionWithName:PMInvalidObjectException
                                                             reason:[NSString stringWithFormat:@"You cannot remove an index to an object of class %@", obj.class]
                                                           userInfo:nil];
            
            [exception raise];
        }
    }];
}

@end

@implementation NSOrderedSet (PMBaseObject)

- (void)pmd_makeObjectsAddIndex:(NSString*)index
{
    [self enumerateObjectsUsingBlock:^(PMBaseObject *obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:PMBaseObject.class])
        {
            [obj addIndex:index order:idx];
        }
        else
        {
            NSException *exception = [NSException exceptionWithName:PMInvalidObjectException
                                                             reason:[NSString stringWithFormat:@"You cannot add an index to an object of class %@", obj.class]
                                                           userInfo:nil];
            
            [exception raise];
        }
    }];
}

- (void)pmd_makeObjectsRemoveIndex:(NSString*)index
{
    [self enumerateObjectsUsingBlock:^(PMBaseObject *obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:PMBaseObject.class])
        {
            [obj removeIndex:index];
        }
        else
        {
            NSException *exception = [NSException exceptionWithName:PMInvalidObjectException
                                                             reason:[NSString stringWithFormat:@"You cannot remove an index to an object of class %@", obj.class]
                                                           userInfo:nil];
            
            [exception raise];
        }
    }];
}

@end


