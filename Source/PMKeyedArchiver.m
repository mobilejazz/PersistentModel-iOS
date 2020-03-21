//
//  PMKeyedArchiver.m
//  PersistentModel
//
//  Created by Joan Martin on 06/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMKeyedArchiver.h"

@implementation PMKeyedArchiver

- (id)initWithContext:(PMObjectContext*)context
{
    self = [super initRequiringSecureCoding:YES];
    if (self)
    {
        _context = context;
    }
    return self;
}

@end
