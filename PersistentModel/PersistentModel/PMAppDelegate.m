//
//  PMAppDelegate.m
//  PersistentModel
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

    [self test2];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    self.window.rootViewController = [UIViewController new];
    
    return YES;
}

- (void)test2
{
    // Creating the URL where we will store the database
    NSURL *url = [applicationCacheDirectory() URLByAppendingPathComponent:@"foo.sql"];
    
    // Instantiating the persistent store
    PMPersistentStore *persistentStore = [[PMSQLiteStore alloc] initWithURL:url];
    
    // Creating an object context connected to the persistent store
    PMObjectContext *objectContext = [[PMObjectContext alloc] initWithPersistentStore:persistentStore];
    
    // Creating a user with index "saul"
    PMUser *user = [[PMUser alloc] initAndInsertToContext:objectContext];
    user.username = @"Saul";
    [user addIndex:@"saul"];
    
    // Creating a video
    PMVideo *video = [[PMVideo alloc] initAndInsertToContext:objectContext];
    video.title = @"My Best Video";
    video.user = user;
//    
    NSLog(@"USER: %@", video.user);
}

- (void)performTest
{
    // Creating the URL where we will store the database
    NSURL *url = [applicationCacheDirectory() URLByAppendingPathComponent:@"PersistentStorage.sql"];
    
    // Instantiating the persistent store
    PMPersistentStore *persistentStore = [[PMSQLiteStore alloc] initWithURL:url];
    
    // Creating an object context connected to the persistent store
    PMObjectContext *objectContext = [[PMObjectContext alloc] initWithPersistentStore:persistentStore];
    
    // Preparing a fetch for "saul"
    PMFetchRequest *fetchRequest = [PMFetchRequest fetchRequestWithClass:PMUser.class index:@"saul"];

    // Fetching all the objects laveled as "saul"
    NSArray *sauls = [objectContext executeFecthRequest:fetchRequest error:nil];
    
    if (sauls.count > 0)
    {
        // If found at least one "saul"
        PMUser *saul = sauls.firstObject;
        
        NSLog(@"Did found object: %@", saul.username);
    }
    else
    {
        // If no "saul" was found
        
        // Fetching all the videos in the store
        PMFetchRequest *fetchRequest = [PMFetchRequest fetchRequestWithClass:PMVideo.class index:nil];
        NSArray *videos = [objectContext executeFecthRequest:fetchRequest error:nil];
        
        if (videos.count == 0)
        {
            // If no videos were found
            
            // Creating a user with index "saul"
            PMUser *user = [[PMUser alloc] initAndInsertToContext:objectContext];
            user.username = @"Saul";
            [user addIndex:@"saul"];
            
            // Creating a video
            PMVideo *video = [[PMVideo alloc] initAndInsertToContext:objectContext];
            video.title = @"My Best Video";
            video.uploaderID = user.objectID;
            
            // Showing the temporal objectIDs of the objects
            NSLog(@"1 USER  OBJECT ID: %@", user.objectID.URIRepresentation);
            NSLog(@"1 VIDEO OBJECT ID: %@", video.objectID.URIRepresentation);
            
            // Saving to the store
            [objectContext saveWithCompletionBlock:^(BOOL succeed) {
                // Showing the final objectIDs of the objects
                NSLog(@"2 USER  OBJECT ID: %@", user.objectID.URIRepresentation);
                NSLog(@"2 VIDEO OBJECT ID: %@", video.objectID.URIRepresentation);
            }];
        }
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
