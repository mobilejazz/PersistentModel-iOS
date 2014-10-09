//
//  PMObjectIndex.m
//  PersistentModelTest
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

@end
