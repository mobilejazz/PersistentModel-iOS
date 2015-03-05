//
//  PMObjectIndex.h
//  PersistentModel
//
//  Created by Joan Martin on 09/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMObjectIndex : NSObject <NSCopying>

- (id)initWithIndex:(NSString*)index order:(NSInteger)order;

@property (nonatomic, assign, readonly) NSInteger order;
@property (nonatomic, strong, readonly) NSString *index;

@end
