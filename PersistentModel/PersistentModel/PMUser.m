//
//  PMUser.m
//  PersistentModel
//
//  Created by Joan Martin on 21/03/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMUser.h"

@implementation PMUser

+ (NSArray*)pmd_persistentPropertyNames
{
    return @[pmd_key(username),
             pmd_key(age),
             pmd_key(avatarURL),
             ];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ - %@, %ld, %@", [super description], _username, (long)_age, _avatarURL.absoluteString];
}

@end
