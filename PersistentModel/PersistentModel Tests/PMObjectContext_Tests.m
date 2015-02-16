//
//  PersistentModel_Tests.m
//  PersistentModel Tests
//
//  Created by Joan Martin on 16/12/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "TestUtilities.h"
#import "PersistentModel.h"

@interface PMObjectContext_Tests : XCTestCase

@end

@implementation PMObjectContext_Tests
{
    PMObjectContext *_objectContext;
}

- (void)setUp
{
    [super setUp];
    
    // Creating an object context (without persistent store)
    _objectContext = [[PMObjectContext alloc] initWithPersistentStore:nil];
}

- (void)tearDown
{
    // Deleting the object context
    _objectContext = nil;
    
    [super tearDown];
}

#pragma mark - Creation

- (void)testObjectIDNull
{
    PMBaseObject *object = [[PMBaseObject alloc] initAndInsertToContext:nil];
    XCTAssert(object.objectID == nil, @"Object ID must be null before insertion");
}

- (void)testObjectIDCreation
{
    PMBaseObject *object = [[PMBaseObject alloc] initAndInsertToContext:_objectContext];
    XCTAssert(object.objectID != nil, @"Object ID cannot be null after insertion");
}

- (void)testObjectContextAssignment
{
    PMBaseObject *object = [[PMBaseObject alloc] initAndInsertToContext:_objectContext];
    XCTAssertEqual(object.context, _objectContext, @"Object context doesn't match the expected context");
}

#pragma mark - Retrival

- (void)testObjectRegisteredRetrival
{
    PMBaseObject *object1 = [[PMBaseObject alloc] initAndInsertToContext:_objectContext];
    PMBaseObject *object2 = [_objectContext objectRegisteredForID:object1.objectID];
    XCTAssertEqual(object1, object2, @"Object registered for ID doesn't match the expected object");
}

- (void)testObjectWithIDRetrival
{
    PMBaseObject *object1 = [[PMBaseObject alloc] initAndInsertToContext:_objectContext];
    PMBaseObject *object2 = [_objectContext objectWithID:object1.objectID];
    XCTAssertEqual(object1, object2, @"Object with ID doesn't match the expected object");
}

#pragma mark - Insertion

- (void)testObjectInsertion
{
    PMBaseObject *object1 = [[PMBaseObject alloc] initAndInsertToContext:nil];
    BOOL succeed = [_objectContext insertObject:object1];
    XCTAssert(succeed, @"insertObject: method must return YES");
    
    PMBaseObject *object2 = [_objectContext objectWithID:object1.objectID];
    XCTAssertEqual(object1, object2, @"Object with ID doesn't match the expected object");
}

- (void)testObjectContextAssignment2
{
    PMBaseObject *object = [[PMBaseObject alloc] initAndInsertToContext:nil];
    XCTAssert(object.context == nil, @"Object context is not nil");
    [_objectContext insertObject:object];
    XCTAssertEqual(object.context, _objectContext, @"Object context doesn't match the expected context");
}

- (void)testObjectInsertTwice
{
    PMBaseObject *object = [[PMBaseObject alloc] initAndInsertToContext:nil];
    BOOL succeed1 = [_objectContext insertObject:object];
    BOOL succeed2 = [_objectContext insertObject:object];
    
    XCTAssert(succeed1 == YES, @"insertObject: method must return YES");
    XCTAssert(succeed2 == YES, @"insertObject: method must return YES when inserting twice an object to the same context");
}

#pragma mark - Deletion

- (void)testObjectDeletionContextRetrival
{
    PMBaseObject *object1 = [[PMBaseObject alloc] initAndInsertToContext:_objectContext];
    [_objectContext deleteObject:object1];
    
    PMBaseObject *object2 = [_objectContext objectRegisteredForID:object1.objectID];
    XCTAssert(object2 == nil, @"Object should not be in the context");
    
    PMBaseObject *object3 = [_objectContext objectWithID:object1.objectID];
    XCTAssert(object3 == nil, @"Object should not be in the context");
}


- (void)testObjectDeletionList
{
    PMBaseObject *object = [[PMBaseObject alloc] initAndInsertToContext:_objectContext];
    [_objectContext deleteObject:object];
    
    NSArray *deletedObjects = [_objectContext deletedObjects];
    XCTAssert(deletedObjects.count == 1, @"Deleted objects should contain only one object");
    XCTAssertEqual(deletedObjects[0], object, @"The deleted object doesn't match the deleted object in the context");
}



@end
