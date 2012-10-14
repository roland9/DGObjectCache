//
//  DGObjectCache.m
//  DGAssetCache
//
//  Created by Damien Glancy on 06/10/2012.
//  Copyright (c) 2012 Damien Glancy. All rights reserved.
//

#import "DGObjectCache.h"

#define ERROR_DOMAIN @"ie.damienglancy.errors"

@interface DGObjectCache ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (assign, nonatomic) NSUInteger capacity;

@property(assign) NSUInteger cacheHits;
@property(assign) NSUInteger cacheMisses;
@property(	assign) NSUInteger totalHits;
@end

#ifdef DEBUG
static dispatch_once_t *once_token_debug;
#endif

@implementation DGObjectCache

#pragma mark - Init

+ (id)cache
{
    return [DGObjectCache cacheFactoryWithCapacity:NSUIntegerMax];
}

+ (id)cacheWithCapacity:(NSUInteger)capacity
{
    return [DGObjectCache cacheFactoryWithCapacity:capacity];
}

+ (id)cacheFactoryWithCapacity:(NSUInteger)capacity
{
    static dispatch_once_t once_token;
    once_token_debug = &once_token;
    static DGObjectCache *cache = nil;

    dispatch_once(&once_token, ^{
        cache = [[self alloc] init];
        cache.capacity = capacity;
        cache.cacheHits = 0;
        cache.cacheMisses = 0;
        cache.totalHits = 0;

        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtURL:[cache cacheDirectory] withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"[OBJECT CACHE] Error %@, %@", error, [error userInfo]);
            cache = nil;
            return;
        }

        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DGObjectCache" withExtension:@"momd"];
        cache.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        cache.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:cache.managedObjectModel];

        NSURL *storeURL = [[cache cacheDirectory] URLByAppendingPathComponent:@"ObjectCache.sqlite"];
        if (![cache.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            NSLog(@"[OBJECT CACHE] Error %@, %@", error, [error userInfo]);
            cache = nil;
            return;
        }

        cache.managedObjectContext = [[NSManagedObjectContext alloc] init];
        [cache.managedObjectContext setPersistentStoreCoordinator:cache.persistentStoreCoordinator];
    });
    return cache;
}

#pragma mark - Public methods

- (void)objectWithURL:(NSURL *)url success:(ObjectCacheSuccessBlock)success failure:(ObjectCacheFailureBlock)failure
{
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];

    [self objectWithRequest:urlRequest success:success failure:failure];
}


- (void)objectWithRequest:(NSURLRequest *)urlRequest success:(ObjectCacheSuccessBlock)success failure:(ObjectCacheFailureBlock)failure {

    NSManagedObject *cachedObject = [self objectFromCoreDataWithURL:urlRequest.URL];
    if (cachedObject) {
        _cacheHits++;
        _totalHits++;
        
        NSData *data = [cachedObject valueForKey:@"data"];
        
        success(data, nil, ObjectLoadSourceCache);
    } else {
        [NSURLConnection sendAsynchronousRequest:urlRequest queue:NSOperationQueue.mainQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             if(error) {
                 failure(error);
             }
             
             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
             NSString *expiryDateString = [httpResponse.allHeaderFields objectForKey:@"Expires"];
             NSDate *expiryDate;
             
             if (expiryDateString) {
                 NSDateFormatter *df = [[NSDateFormatter alloc] init];
                 df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                 df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
                 df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
                 
                 expiryDate = [df dateFromString:expiryDateString];
             }
             
             if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                 [self insertObjectIntoCoreDataWithURL:urlRequest.URL data:data expiryDate:expiryDate];
                 _cacheMisses++;
                 _totalHits++;
                 success(data, response, ObjectLoadSourceNetwork);
             } else {
                 NSError *localError = [NSError errorWithDomain:ERROR_DOMAIN code:httpResponse.statusCode userInfo:nil];
                 failure(localError);
             }
         }];
    }

}


- (void)removeObjectWithURL:(NSURL *)url success:(ObjectCacheSuccessBlock)success failure:(ObjectCacheFailureBlock)failure
{
    NSManagedObject *cachedObject = [self objectFromCoreDataWithURL:url];
    [_managedObjectContext deleteObject:cachedObject];

    NSError *error;
    [_managedObjectContext save:&error];
    if (error) {
        NSLog(@"[OBJECT CACHE] Error occured deleting object %@ from store. %@", url.absoluteString, error.localizedDescription);
        failure(error);
    } else {
        NSLog(@"[OBJECT CACHE] Deleted object for %@ from store", url.absoluteString);
        success(nil, nil, NSIntegerMax);
    }
}

- (void)resetObjectCache
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"CachedObject" inManagedObjectContext:_managedObjectContext]];
    fetchRequest.includesPropertyValues = NO;

    NSError *error;
    NSArray *allObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
         NSLog(@"[OBJECT CACHE] Error occured getting all objects in core data store. %@", error.localizedDescription);
        return;
    }

    for (NSManagedObject *cachedObject in allObjects) {
        [_managedObjectContext deleteObject:cachedObject];
    }

    [_managedObjectContext save:&error];

    _cacheHits = 0;
    _cacheMisses = 0;
    _totalHits = 0;

    NSLog(@"[OBJECT CACHE] Removed %d object(s) from cache", allObjects.count);
}

- (NSUInteger)count
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"CachedObject" inManagedObjectContext:_managedObjectContext]];
    fetchRequest.includesPropertyValues = NO;

    NSError *error;
    NSUInteger count = [_managedObjectContext countForFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"[OBJECT CACHE] Error occured getting all objects in core data store. %@", error.localizedDescription);
        return 0;
    }

    return count;
}

- (void)printStatistics
{
    NSLog(@"Total Hits: %d, Cache Misses: %d, Cache Hits: %d", _totalHits, _cacheMisses, _cacheHits);
}

#pragma mark - Private methods

- (void)insertObjectIntoCoreDataWithURL:(NSURL *)url data:(NSData *)data expiryDate:(NSDate *)expiryDate;
{
    if (self.count+1 > self.capacity) {
        NSLog(@"[OBJECT CACHE] Making room for new object as the cache has reached its capacity (%d)", _capacity);
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"CachedObject" inManagedObjectContext:_managedObjectContext]];
        fetchRequest.fetchLimit = 1;

        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"cachedDate" ascending:YES];
        fetchRequest.sortDescriptors = @[sort];

        NSError *error;
        NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (error) {
            NSLog(@"[OBJECT CACHE] Error occured finding oldest object in store. %@", error.localizedDescription);
        } else {
            if (results.count == 1) {
                NSManagedObject *cachedObject = (NSManagedObject *)results[0];
                NSString *cachedObjectUrl = [cachedObject valueForKey:@"url"];
                [_managedObjectContext deleteObject:cachedObject];

                [_managedObjectContext save:&error];
                if (error) {
                    NSLog(@"[OBJECT CACHE] Error occured deleting object %@ from store. %@", cachedObjectUrl, error.localizedDescription);
                } else {
                    NSLog(@"[OBJECT CACHE] Deleted object for %@ from store", cachedObjectUrl);
                }                
            }
        }
    }

    NSManagedObject *object = (NSManagedObject *)[NSEntityDescription insertNewObjectForEntityForName:@"CachedObject" inManagedObjectContext:_managedObjectContext];

    [object setValue:url.absoluteString forKey:@"url"];
    [object setValue:data forKey:@"data"];
    [object setValue:[NSDate date] forKey:@"cachedDate"];
    [object setValue:expiryDate forKey:@"expiryDate"];

    NSError *error;
    [_managedObjectContext save:&error];
    if (error) {
        NSLog(@"[OBJECT CACHE] Error occured inserting object %@ into store. %@", url.absoluteString, error.localizedDescription);
    } else {
        NSLog(@"[OBJECT CACHE] Inserted object for %@ into store", url.absoluteString);
    }
}

- (NSManagedObject *)objectFromCoreDataWithURL:(NSURL *)url
{
    NSFetchRequest *fetchRequest = [_managedObjectModel fetchRequestFromTemplateWithName:@"ObjectForUrl" substitutionVariables:@{@"URL" : url}];

    NSError* error = nil;
    NSArray* results = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];

    if (results && results.count == 1) {
        NSManagedObject *cachedObject = (NSManagedObject *)results[0];

        NSDate *expiryDate = [cachedObject valueForKey:@"expiryDate"];

        if (expiryDate) {
            if ([expiryDate compare:[NSDate date]]==NSOrderedAscending) {
                // cached resource has expired
                [_managedObjectContext deleteObject:cachedObject];

                NSError *error;
                [_managedObjectContext save:&error];
                if (error) {
                    NSLog(@"[OBJECT CACHE] Error occured deleting object %@ from store. %@", url.absoluteString, error.localizedDescription);
                } else {
                    NSLog(@"[OBJECT CACHE] Deleted object for %@ from store", url.absoluteString);
                }

                return nil;
            }
        }
        
        return cachedObject;
    } else {
        return nil;
    }
}

- (NSURL *)cacheDirectory
{
    return [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"ie.damienglancy.objectcache"];
}

#ifdef DEBUG
+ (void)resetDispatchOnceToken
{
    *once_token_debug = 0;
}
#endif


@end