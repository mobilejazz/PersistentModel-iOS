//
//  TestUtilities.m
//  PersistentModel
//
//  Created by Joan Martin on 16/12/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "TestUtilities.h"

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