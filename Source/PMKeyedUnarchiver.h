//
//  PMKeyedUnarchiver.h
//  PersistentModelTest
//
//  Created by Joan Martin on 06/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PMObjectContext.h"

@interface PMKeyedUnarchiver : NSKeyedUnarchiver

- (id)initForReadingWithData:(NSData *)data context:(PMObjectContext*)context;

@property (nonatomic, strong, readonly) PMObjectContext *context;


@end
