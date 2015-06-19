//
//  PMSQLiteObject.m
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

#import "PMSQLiteObject.h"

#import "PMSQLiteStore_Private.h"

#import "PMObjectID_Private.h"

@implementation PMSQLiteObject

@synthesize persistentStore = _persistentStore;

- (id)init
{
    return [self initWithID:NSNotFound type:nil];
}

- (id)initWithID:(NSInteger)dbID type:(NSString*)type
{
    self = [super init];
    if (self)
    {
        self.dbID = dbID;
        self.type = type;
        _hasChanges = NO;
    }
    return self;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@: <id:%ld> <type:%@> <lastUpdate:%@> <dataLength:%ld>",[super description], (long)self.dbID, self.type, self.lastUpdate.description, (long)self.data.length];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]])
    {
        PMSQLiteObject *sqlObject = object;
        return self.dbID == sqlObject.dbID && self.dbID != NSNotFound;
    }
    
    return NO;
}

- (NSUInteger)hash
{
    return @(self.dbID).hash;
}

#pragma mark Properties

- (void)pmd_setHasChanges:(BOOL)hasChanges
{
    _hasChanges = hasChanges;
    
    if (_hasChanges)
        [self.persistentStore pmd_didChangePersistentObject:self];
}

- (void)setLastUpdate:(NSDate *)lastUpdate
{
    BOOL sameValue = [self.lastUpdate isEqual:lastUpdate];
    [super setLastUpdate:lastUpdate];
    [self pmd_setHasChanges:_hasChanges || !sameValue];
}

- (void)setData:(NSData *)data
{
    BOOL sameValue = [self.data isEqualToData:data];
    [super setData:data];
    [self pmd_setHasChanges:_hasChanges || !sameValue];
}

#pragma mark Key Value Coding

- (void)setValue:(id)value forKey:(NSString *)key
{
    _hasChanges = ![value isEqual:[self valueForKey:key]] || _hasChanges;
    [super setValue:value forKey:key];
}

@end
