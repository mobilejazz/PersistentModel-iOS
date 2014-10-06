//
//  PMFetchRequest.h
//  PersistentModelTest
//
//  Created by Joan Martin on 06/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMFetchRequest : NSObject

+ (PMFetchRequest*)fetchRequestWithType:(NSString*)type;
+ (PMFetchRequest*)fetchRequestWithType:(NSString*)type index:(NSString*)index;

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *index;

@property (nonatomic, assign) NSInteger fetchLimit;
@property (nonatomic, assign) NSInteger fetchOffset;

@end
