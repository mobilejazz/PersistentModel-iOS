//
//  PersistentModel_Tests.m
//  PersistentModel Tests
//
//  Created by Joan Martin on 16/12/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "PersistentModel.h"

NSURL* applicationCacheDirectory()
{
    static NSURL *url = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachePath = [pathList[0] stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
        
        // Create cache path if it doesn't exist, yet:
        BOOL isDir = NO;
        NSError *error;
        if (! [[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO)
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error];
        
        url = [NSURL fileURLWithPath:cachePath];
    });
    
    return url;
}

@interface PersistentModel_Tests : XCTestCase

@end

@implementation PersistentModel_Tests
{
    PMPersistentStore *_persistentStore;
    PMObjectContext *_objectContext;
}

- (void)setUp
{
    [super setUp];

    // Creating the URL where we will store the database
    NSURL *url = [applicationCacheDirectory() URLByAppendingPathComponent:@"test.sql"];
    
    // Instantiating the persistent store
    _persistentStore = [[PMSQLiteStore alloc] initWithURL:url];
    
    // Creating an object context connected to the persistent store
    _objectContext = [[PMObjectContext alloc] initWithPersistentStore:_persistentStore];
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

#pragma mark - Index


@end
