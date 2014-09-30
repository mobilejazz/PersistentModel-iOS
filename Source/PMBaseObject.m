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
#import "PMBaseObject+PrivateMethods.h"

#import "PMBaseObject_Private.h"
#import "PMObjectID_Private.h"
#import "PMObjectContext.h"

NSString * const PMBaseObjectNilKeyException = @"PMBaseObjectNilKeyException";


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

#pragma mark Public Methods

//+ (instancetype)objectWithKey:(NSString *)key inContext:(PMObjectContext*)context allowsCreation:(BOOL)flag;
//{
//    if (key == nil)
//    {
//        NSString *reason = [NSString stringWithFormat:@"Trying to fetch an object of type %@ with a nil key.", NSStringFromClass(self)];
//        NSException *exception = [NSException exceptionWithName:PMBaseObjectNilKeyException reason:reason userInfo:nil];
//        [exception raise];
//        return nil;
//    }
//    
//    PMBaseObject *baseObject = [context objectForKey:key];
//    
//    if (baseObject)
//        return baseObject;
//    
//    if (flag)
//    {        
//        baseObject = [[self alloc] initWithKey:key context:context];
//        return baseObject;
//    }
//    
//    return nil;
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

#pragma mark Public Methods

@end


@implementation PMBaseObject (Subclassing)

+ (NSArray*)pmd_persistentPropertyNames
{
    // Subclasses may override
    return @[];
}

@end

