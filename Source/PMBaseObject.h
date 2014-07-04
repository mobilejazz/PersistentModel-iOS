//
//  PMBaseObject.h
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

extern NSString * const PMBaseObjectNilKeyException;

@class PMObjectContext;

/**
 * Superclass of persistent objects. Persistent objects will have to be a subclass of this one.
 *
 * In order to persist properties, you can choose between:
 *   1. Manually encode and decode your properties using the NSCoding protocol methods
 *   2. Override the method `keysForPersistentValues` and return a set of strings with the names of those properties you want to persist. Values will be retrieved using KVC.
 **/
@interface PMBaseObject : NSObject <NSCoding, NSCopying>


/** ---------------------------------------------------------------- **
 *  @name Creating instances and initializing
 ** ---------------------------------------------------------------- **/

/**
 * Default init method.
 * @param key The key to identify the created object. This key has to be unique for the given context.
 * @param context The context to register the object. Can be nil.
 * @discussion If initializing the object with an existing key in the given context, this method retuns nil.
 **/
- (id)initWithKey:(NSString*)key context:(PMObjectContext*)context;

/**
 * Default static method for creating an object.
 * @param key The key to identify the created object. This key has to be unique for the given context and cannot be nil.
 * @param context The context to register the object. Can be nil.
 * @param flag If NO, this method will return only previously created objects and won't create new instances for the given key.
 * @discussion If initializing the object with a repeated key for the given context, this method retuns nil.
 **/
+ (instancetype)objectWithKey:(NSString *)key inContext:(PMObjectContext*)context allowsCreation:(BOOL)flag;


/** ---------------------------------------------------------------- **
 *  @name Object context management
 ** ---------------------------------------------------------------- **/

/**
 * The context where the object is registered to.
 * @discussion This value can be nil if the object is not registered in any context.
 **/
@property (nonatomic, weak, readonly) PMObjectContext *context;

/**
 * In order to delete an object from the context, call this method.
 * @discussion This method invokes automatically the method 'deleteObject' from the registered PMObjectContext.
 **/
- (void)deleteObjectFromContext;

/**
 * Use this method in order to regsiter a new object to the context.
 * @param context The context to regsiter the current object.
 * @return YES if succeed, otherwise NO.
 * @discussion If another object with the same key is registered in the context, this method will fail to register the new object and return NO. It is responsibility of the user to unregister the object from the current context before calling this method.
 **/
- (BOOL)registerToContext:(PMObjectContext*)context;


/** ---------------------------------------------------------------- **
 *  @name Main Properties
 ** ---------------------------------------------------------------- **/

/** 
 * The unique key that identifies the object
 **/
@property (nonatomic, strong) NSString *key;

/** 
 * The date of the last update.
 * @discussion It is your responsability to refresh this property and set the latest change date of the current object. By default the nothing is done.
 **/
@property (nonatomic, strong) NSDate *lastUpdate;

/** 
 * YES if any attribute has been changed since the last save, otherwise NO 
 * @discussion The tracking of this property is done via KVC. If you set properties directly, you must set the has changes flag manually. Setting this flag to YES marks this object to be saved in the next context saving call. 
 **/
@property (nonatomic, assign) BOOL hasChanges;

@end


#define mjz_key(arg) NSStringFromSelector(@selector(arg))

@interface PMBaseObject (Subclassing)

/**
 * Set of property names that are automatically persistent via KVC access.
 * @discussion Subclasses may override this method to mark those properties to be persistent. Values will be accessed via KVC. By default this class returns an empty set.
 **/
+ (NSArray*)pmd_persistentPropertyNames;

@end
