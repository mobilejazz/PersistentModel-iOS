//
//  PMAppDelegate.m
//  PersistentModelTest
//
//  Created by Joan Martin on 27/02/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import "PMAppDelegate.h"

#import "PMObjectContext.h"
#import "PMSQLiteStore.h"

#import "PMVideo.h"
#import "PMUser.h"

NSURL* applicationCacheDirectory();

@implementation PMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [self performTest];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    self.window.rootViewController = [UIViewController new];
    
    return YES;
}

- (void)performTest
{
    NSURL *url = [applicationCacheDirectory() URLByAppendingPathComponent:@"PersistentStorage.sql"];
    
    NSLog(@"%@", url);
    
//    [[NSFileManager defaultManager] removeItemAtURL:url error:nil]; // <------ COMMENT AND UNCOMMENT THIS LINE TO DELETE THE PERSISTENT STORAGE
    
    // Creating the persistent store
    PMPersistentStore *persistentStore = [[PMSQLiteStore alloc] initWithURL:url];
    
    // Creating an object context connected to the above persistent store
    PMObjectContext *objectContext = [[PMObjectContext alloc] initWithPersistentStore:persistentStore];
    
    NSArray *videos = [objectContext objectsOfClass:PMVideo.class];

//    PMVideo *video = [TMVideo objectForQuery:@"me"];
//    
//    [TMVideo fectchQuery:@"me" completionBlock:^(NSArray *objects){
//        
//    }];
    
    NSLog(@"VIDEOS: %@", videos.description);
    
    if (videos.count == 0)
    {
        PMUser *user = [[PMUser alloc] initAndInsertToContext:objectContext];
        user.username = @"Saul";
        
        PMVideo *video = [[PMVideo alloc] initAndInsertToContext:objectContext];
        video.title = @"My Best Video";
        video.uploaderID = user.objectID;
        
        NSLog(@"1 USER  OBJECT ID: %@", user.objectID.URIRepresentation);
        NSLog(@"1 VIDEO OBJECT ID: %@", video.objectID.URIRepresentation);
    
        [objectContext saveWithCompletionBlock:^(BOOL succeed) {
            NSLog(@"2 USER  OBJECT ID: %@", user.objectID.URIRepresentation);
            NSLog(@"2 VIDEO OBJECT ID: %@", video.objectID.URIRepresentation);
        }];
    }
    else
    {
        PMVideo *video = videos.firstObject;
        PMUser *user = video.uploader;
        
        NSLog(@"VIDEO: %@", video.title);
        NSLog(@"USER: %@", user.username);
    }
}

@end


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
