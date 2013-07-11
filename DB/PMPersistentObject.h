//
//  PMPersistentObject.h
//  Created by Joan Martin on 2/15/13.
//  Take a look to my repos at http://github.com/vilanovi
//

#import <Foundation/Foundation.h>

@protocol PMPersistentObject <NSObject>

@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic) NSData *data;
@property (nonatomic) NSDate *lastUpdate;

@end
