//
//  PMVideo.m
//  PersistentModel
//
//  Created by Joan Martin on 21/03/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMVideo.h"
#import "PMUser.h"

@implementation PMVideo

@dynamic user;

+ (NSArray*)pmd_persistentPropertyNames
{
    return @[pmd_key(title),
             pmd_key(uploaderID),
             ];
}

- (PMUser*)uploader
{
    if (_uploaderID)
        return [self.context objectWithID:_uploaderID];
    
    return nil;
}

@end
