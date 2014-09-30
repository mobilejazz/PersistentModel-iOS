//
//  PMVideo.m
//  PersistentModelTest
//
//  Created by Joan Martin on 21/03/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMVideo.h"
#import "PMUser.h"

@implementation PMVideo

+ (NSArray*)pmd_persistentPropertyNames
{
    return @[mjz_key(title),
             mjz_key(uploaderID),
             ];
}

- (PMUser*)uploader
{
    if (_uploaderID)
        return [self.context objectForObjectID:_uploaderID];
    
    return nil;
}

@end
