//
//  PMObjectIndex.m
//  PersistentModel
//
//  Created by Joan Martin on 09/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMObjectIndex.h"

@implementation PMObjectIndex

- (id)initWithIndex:(NSString*)index order:(NSInteger)order
{
    self = [super init];
    if (self)
    {
        _index = index;
        _order = order;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    PMObjectIndex *copy = [[PMObjectIndex allocWithZone:zone] initWithIndex:_index order:_order];
    return copy;
}

- (NSUInteger)hash
{
    return [_index hash];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:PMObjectIndex.class])
    {
        PMObjectIndex *objectIndex = object;
        
        if ([objectIndex.index isEqualToString:_index])
            return YES;
    }
    return NO;
}

@end
