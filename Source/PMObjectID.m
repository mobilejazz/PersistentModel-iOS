//
//  PMObjectID.m
//  PersistentModelTest
//
//  Created by Joan Martin on 30/09/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMObjectID_Private.h"

static NSString * const kPMObjectIDScheme = @"pmoid";
static NSString * const kPMObjectIDTemporalScheme = @"pmtid";

@implementation PMObjectID

@synthesize temporaryID = _temporaryID;

- (id)init
{
    self = [super init];
    if (self)
    {
        _dbID = NSNotFound;
        _type = nil;
        _temporaryID = YES;
        _persistentStore = nil;
    }
    return self;
}

- (id)initWithDbID:(NSInteger)dbID type:(NSString*)type persistentStore:(PMPersistentStore*)persistentStore
{
    self = [super init];
    if (self)
    {
        _dbID = dbID;
        _type = type;
        _temporaryID = persistentStore != nil ? NO : YES;
        _persistentStore = persistentStore;
    }
    return self;
}

- (id)initWithTempraryID:(NSInteger)temporaryID type:(NSString*)type
{
    self = [super init];
    if (self)
    {
        _dbID = temporaryID;
        _type = type;
        _temporaryID = YES;
        _persistentStore = nil;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        _dbID = [aDecoder decodeIntegerForKey:@"dbID"];
        _type = [aDecoder decodeObjectForKey:@"type"];
        _temporaryID = NO;
        
        _persistentStore = nil; // <-- MUST SET THIS LATER!
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    NSAssert(_temporaryID == NO, @"When encoding, the object ID cannot be temporal");
    
    [aCoder encodeInteger:_dbID forKey:@"dbID"];
    [aCoder encodeObject:_type forKey:@"type"];
}


- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:self.class])
    {
        PMObjectID *objectID = object;
        return objectID.dbID == _dbID && objectID.isTemporaryID == _temporaryID;
    }
    
    return false;
}

- (NSUInteger)hash
{
    return self.URIRepresentation.hash;
}

#pragma mark Properties

- (Class)typeClass
{
    return NSClassFromString(_type);
}

- (BOOL)isTemporaryID
{
    return _temporaryID;
}

- (PMPersistentStore*)persistentStore
{
    return _persistentStore;
}

#pragma mark Public Methods


- (NSURL*)URIRepresentation
{
    NSString *scheme = _temporaryID ? kPMObjectIDTemporalScheme : kPMObjectIDScheme;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/%ld", scheme, _type, (long)_dbID]];
    
    return url;
}

@end
