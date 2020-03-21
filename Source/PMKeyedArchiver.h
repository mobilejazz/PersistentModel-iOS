//
//  PMKeyedArchiver.h
//  PersistentModel
//
//  Created by Joan Martin on 06/10/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PMObjectContext.h"

@interface PMKeyedArchiver : NSKeyedArchiver

- (id)initWithContext:(PMObjectContext*)context;

@property (nonatomic, strong, readonly) PMObjectContext *context;

@end
