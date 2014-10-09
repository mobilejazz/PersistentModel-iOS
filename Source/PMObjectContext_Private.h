//
//  PMObjectContext_Private.h
//  PersistentModelTest
//
//  Created by Joan Martin on 09/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMObjectContext.h"

@interface PMObjectContext ()

- (NSArray*)pmd_fetchIndexesForObjectWithID:(PMObjectID*)objectID;

@end
