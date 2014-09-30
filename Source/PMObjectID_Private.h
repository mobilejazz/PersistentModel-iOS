//
//  PMObjectID_Private.h
//  PersistentModelTest
//
//  Created by Joan Martin on 30/09/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMObjectID.h"

@interface PMObjectID ()

- (id)initWithTempraryID:(NSInteger)temporaryID type:(NSString*)type;

- (id)initWithDbID:(NSInteger)dbID type:(NSString*)type persistentStore:(PMPersistentStore*)persistentStore;

/**
 * The database identifier.
 **/
@property (nonatomic, assign) NSInteger dbID;

/**
 * Boolean value indicating if the stored id is temporal or not.
 **/
@property (nonatomic, readwrite, getter=isTemporaryID) BOOL temporaryID;

/**
 * Type of object.
 * @discussion The value contained in this property is a string value with the name of a class.
 **/
@property (nonatomic, strong) NSString *type;

/**
 * The related persistent store corresponding to the `dbID`.
 **/
@property (nonatomic, readwrite, strong) PMPersistentStore *persistentStore;

@end
