//
//  CachedObject.h
//  DGAssetCache
//
//  Created by Damien Glancy on 06/10/2012.
//  Copyright (c) 2012 Damien Glancy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CachedObject : NSManagedObject

@property (strong, nonatomic) NSData * data;
@property (strong, nonatomic) NSDate * expiryDate;
@property (strong, nonatomic) NSDate * cachedDate;
@property (strong, nonatomic) NSString * url;

@end
