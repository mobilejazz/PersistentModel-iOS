//
//  NSArray+PMBaseObject.m
//  PersistentModelTest
//
//  Created by Joan Martin on 08/12/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "NSArray+PMBaseObject.h"
#import "PMBaseObject.h"

NSString * const PMDInvalidObjectException = @"PMDInvalidObjectException";

@implementation NSArray (PMBaseObject)

- (void)pmd_addIndex:(NSString*)index
{
    [self enumerateObjectsUsingBlock:^(PMBaseObject *obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:PMBaseObject.class])
        {
            [obj addIndex:index order:idx];
        }
        else
        {
            NSException *exception = [NSException exceptionWithName:PMDInvalidObjectException
                                                             reason:[NSString stringWithFormat:@"You cannot add an index to an object of class %@", obj.class]
                                                           userInfo:nil];
            
            [exception raise];
        }
    }];
}

- (void)pmd_removeIndex:(NSString*)index
{
    [self enumerateObjectsUsingBlock:^(PMBaseObject *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:PMBaseObject.class])
        {
            [obj removeIndex:index];
        }
        else
        {
            NSException *exception = [NSException exceptionWithName:PMDInvalidObjectException
                                                             reason:[NSString stringWithFormat:@"You cannot remove an index to an object of class %@", obj.class]
                                                           userInfo:nil];
            
            [exception raise];
        }
    }];
}

@end
