//
//  PMKeyedUnarchiver.m
//  PersistentModelTest
//
//  Created by Joan Martin on 06/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMKeyedUnarchiver.h"

@implementation PMKeyedUnarchiver

- (id)initForReadingWithData:(NSData *)data
{
    return [self initForReadingWithData:data context:nil];
}

- (id)initForReadingWithData:(NSData *)data context:(PMObjectContext*)context
{
    self = [super initForReadingWithData:data];
    if (self)
    {
        _context = context;
    }
    return self;
}

@end
