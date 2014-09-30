//
//  PMBaseObject_Private.h
//  PersistentModelTest
//
//  Created by Joan Martin on 30/09/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMBaseObject.h"

@interface PMBaseObject ()

@property (nonatomic, strong) PMObjectID *objectID;
@property (nonatomic, weak, readwrite) PMObjectContext *context;

+ (NSArray*)pmd_allPersistentPropertyNames;

@end
