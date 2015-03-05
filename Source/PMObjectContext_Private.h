//
//  PMObjectContext_Private.h
//  PersistentModel
//
//  Created by Joan Martin on 09/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMObjectContext.h"

@class PMObjectIndex;

@interface PMObjectContext ()

- (NSArray*)pmd_fetchIndexesForObjectWithID:(PMObjectID*)objectID;

- (void)pmd_didRegisterIndex:(PMObjectIndex*)index object:(PMBaseObject*)object;
- (void)pmd_didDeleteIndex:(PMObjectIndex*)index object:(PMBaseObject*)object;

@end
