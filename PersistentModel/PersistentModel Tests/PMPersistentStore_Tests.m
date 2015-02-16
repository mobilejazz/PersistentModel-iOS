//
//  PMPersistentStore_Tests.m
//  PersistentModel
//
//  Created by Joan Martin on 16/12/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "TestUtilities.h"
#import "PersistentModel.h"

@interface PMPersistentStore_Tests : XCTestCase

@end

@implementation PMPersistentStore_Tests
{
    PMPersistentStore *_persistentStore;
}

- (void)setUp
{
    [super setUp];

    // Creating the URL where we will store the database
    NSURL *url = [applicationCacheDirectory() URLByAppendingPathComponent:@"persistentstore_test.sql"];
    
    // Instantiating the persistent store
    _persistentStore = [[PMSQLiteStore alloc] initWithURL:url];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample
{
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
