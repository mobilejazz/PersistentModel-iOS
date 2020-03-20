//
//  PMKeyedArchiver.m
//  PersistentModel
//
//  Created by Joan Martin on 06/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMKeyedArchiver.h"

@implementation PMKeyedArchiver

- (id)initForWritingWithMutableData:(NSMutableData *)data
{
    return [self initForWritingWithMutableData:data context:nil];
}

- (id)initForWritingWithMutableData:(NSMutableData *)data context:(PMObjectContext*)context
{
    self = [super initRequiringSecureCoding:YES];
    if (self)
    {
        _context = context;
    }
    return self;
}

@end
