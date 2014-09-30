//
//  PMObjectID.h
//  PersistentModelTest
//
//  Created by Joan Martin on 30/09/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PMPersistentStore;

@interface PMObjectID : NSObject <NSCoding>

@property (nonatomic, readonly) Class typeClass;
@property (nonatomic, readonly, getter=isTemporaryID) BOOL temporaryID;
@property (nonatomic, readonly, strong) PMPersistentStore *persistentStore;

- (NSURL *)URIRepresentation;

@end
