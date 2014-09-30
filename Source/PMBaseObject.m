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
#import "PMObjectContext.h"

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
        
        [context insertObject:self];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
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

@end


@implementation PMBaseObject (Subclassing)

+ (NSArray*)pmd_persistentPropertyNames
{
    // Subclasses may override
    return @[];
}

@end

