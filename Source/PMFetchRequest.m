//
//  PMFetchRequest.m
//  PersistentModel
//
//  Created by Joan Martin on 06/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMFetchRequest.h"

@implementation PMFetchRequest

+ (PMFetchRequest*)fetchRequestWithClass:(Class)objectClass
{
    return [[PMFetchRequest alloc] initWithClass:objectClass index:nil];
}

+ (PMFetchRequest*)fetchRequestWithClass:(Class)objectClass index:(NSString*)index
{
    return [[PMFetchRequest alloc] initWithClass:objectClass index:index];
}

- (id)initWithClass:(Class)objectClass index:(NSString*)index
{
    self = [super init];
    if (self)
    {
        _objectClass = objectClass;
        _index = index;
        
        _fetchLimit = 0;
        _fetchOffset = 0;
    }
    return self;
}

@end
