//
//  PMObjectID.h
//  PersistentModel
//
//  Created by Joan Martin on 30/09/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PMPersistentStore;

/**
 * The object ID identifies uniquely each object in the persistent store and object context.
 * Objects can be temporal or final. Temporal objects haven't been saved yet to any persistent store.
 **/
@interface PMObjectID : NSObject <NSSecureCoding>

/**
 * The class of the object represented by the object ID.
 **/
@property (nonatomic, readonly) Class typeClass;

/**
 * YES if the object is temporary, NO otherwise.
 * @discussion Temporary objects haven't been saved yet to the persistent store.
 **/
@property (nonatomic, readonly, getter=isTemporaryID) BOOL temporaryID;

/**
 * The associated persistent store. Can be nil if the object has not been saved yet.
 **/
@property (nonatomic, readonly, strong) PMPersistentStore *persistentStore;

/**
 * A URL representation of the object id.
 * @return A URL representation of the object id.
 **/
- (NSURL *)URIRepresentation;

@end
