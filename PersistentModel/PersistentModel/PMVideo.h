//
//  PMVideo.h
//  PersistentModel
//
//  Created by Joan Martin on 21/03/14.
//  Copyright (c) 2014 Joan Martin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PersistentModel.h"

@class PMUser;

@interface PMVideo : PMBaseObject

@property (nonatomic, strong) NSString *title;

@property (nonatomic, strong) PMObjectID *uploaderID;

@property (nonatomic, strong) PMUser *user;


- (PMUser*)uploader;

@end
