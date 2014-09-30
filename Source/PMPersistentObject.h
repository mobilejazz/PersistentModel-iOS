//
//  PMPersistentObject.h
//  Created by Joan Martin.
//  Take a look to my repos at http://github.com/vilanovi
//
// Copyright (c) 2013 Joan Martin, vilanovi@gmail.com.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

#import <Foundation/Foundation.h>

@class PMObjectID;
@class PMPersistentStore;

/**
 * Persistent objects must implement this protocol to adopt the required schema: `key` (String), `type` (String), `lastUpdate` (Date) and `data` (BLOB).
 **/
@interface PMPersistentObject : NSObject

/**
 * Used to identify the model object.
 **/
@property (nonatomic, assign) NSInteger dbID;

/**
 * The type of the binary data.
 **/
@property (nonatomic, strong) NSString *type;

/**
 * Used to retrieve the last update of the model object.
 **/
@property (nonatomic, strong) NSDate *lastUpdate;

/**
 * Used to store the model object data.
 **/
@property (nonatomic, strong) NSData *data;

/**
 * The associated persistent store.
 **/
@property (nonatomic, weak) PMPersistentStore *persistentStore;

@end
