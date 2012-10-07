//
//  DGAssetCacheTests.m
//  DGAssetCacheTests
//
//  Created by Damien Glancy on 06/10/2012.
//  Copyright (c) 2012 Damien Glancy. All rights reserved.
//

#import "DGAssetCacheTests.h"
#import "DGObjectCache.h"

@implementation DGAssetCacheTests

- (void)setUp
{
    [super setUp];
    // Set-up code here.
    [[DGObjectCache cache] reset];
    [DGObjectCache resetDispatchOnceToken];
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)testObjectCacheFactory
{
    DGObjectCache *cache = [DGObjectCache cache];
    STAssertNotNil(cache, @"Cache should not be nil");
}

- (void)testObjectCacheIsSingleton
{
    DGObjectCache *cacheA = [DGObjectCache cache];
    STAssertNotNil(cacheA, @"CacheA should not be nil");

    DGObjectCache *cacheB = [DGObjectCache cache];
    STAssertNotNil(cacheB, @"CacheB should not be nil");

    STAssertEqualObjects(cacheA, cacheB, @"CacheA and CacheB should be equal objects as they are singletons");
}

- (void)testDispatchOnceReset
{
    DGObjectCache *cacheA = [DGObjectCache cache];
    STAssertNotNil(cacheA, @"CacheA should not be nil");

    [DGObjectCache resetDispatchOnceToken];

    DGObjectCache *cacheB = [DGObjectCache cache];
    STAssertNotNil(cacheB, @"CacheB should not be nil");

    if (cacheA == cacheB) {
        STFail(@"Cache singleton did not reset");
    }
}

- (void)testDefaultObjectCacheCapacity
{
    DGObjectCache *cache = [DGObjectCache cache];
    if (cache.capacity != NSUIntegerMax) {
        STFail(@"Capacity should be INTEGER_MAX");
    }
}

- (void)testDefaultObjectCacheCapacity500
{
    DGObjectCache *cache = [DGObjectCache cacheWithCapacity:500];
    if (cache.capacity != 500) {
        STFail(@"Capacity should be 500");
    }
}

- (void)testDefaultObjectCacheCapacity10000
{
    DGObjectCache *cache = [DGObjectCache cacheWithCapacity:10000];
    if (cache.capacity != 10000) {
        STFail(@"Capacity should be 10000");
    }
}

- (void)testObjectCacheLoadsAnValidRemoteObject
{
    DGObjectCache *cache = [DGObjectCache cache];
    [cache reset];

    [cache objectWithURL:[NSURL URLWithString:@"http://damienglancy.ie/blogimages/weather1.png"] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
        STAssertNotNil(object, @"An object should have been returned.");
        if (!object) {
            [self notify:SenAsyncTestCaseStatusFailed];
        } else {
            if (source != ObjectLoadSourceNetwork) {
                STFail(@"Object should have been loaded from network and not cache");
                [self notify:SenAsyncTestCaseStatusFailed];
            }
            [self notify:SenAsyncTestCaseStatusSucceeded];
        }
    } failure:^(NSError *error) {
        STFail(@"An error should not have occured while attempting to load remote object http://damienglancy.ie/blogimages/weather1.png");
        [self notify:SenAsyncTestCaseStatusFailed];
    }];

    [self waitForStatus:SenAsyncTestCaseStatusSucceeded timeout:STANDARD_TIMEOUT_IN_SECS];
}

- (void)testObjectCacheLoadsAnInvalidRemoteObject
{
    DGObjectCache *cache = [DGObjectCache cache];
    [cache reset];

    [cache objectWithURL:[NSURL URLWithString:@"http://damienglancy.ie/blogimages/invalid.png"] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
        STFail(@"An error should have occured while attempting to load remote object http://damienglancy.ie/blogimages/invalid.png");
        [self notify:SenAsyncTestCaseStatusFailed];
    } failure:^(NSError *error) {
        STAssertNotNil(error, @"An error object should have been returned");
        if (!error) {
            [self notify:SenAsyncTestCaseStatusFailed];
        }
        [self notify:SenAsyncTestCaseStatusSucceeded];
    }];

    [self waitForStatus:SenAsyncTestCaseStatusSucceeded timeout:STANDARD_TIMEOUT_IN_SECS];
}

- (void)testObjectCacheResetWorks
{
    DGObjectCache *cache = [DGObjectCache cache];
    [cache reset];

    if (cache.count !=0) {
        STFail(@"Cache count should be 0");
        [self notify:SenAsyncTestCaseStatusFailed];
    }

    [cache objectWithURL:[NSURL URLWithString:@"http://damienglancy.ie/blogimages/weather1.png"] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
        STAssertNotNil(object, @"An object should have been returned.");
        if (!object) {
            [self notify:SenAsyncTestCaseStatusFailed];
        } else {
            if (source != ObjectLoadSourceNetwork) {
                STFail(@"Object should have been loaded from network and not cache");
                [self notify:SenAsyncTestCaseStatusFailed];
            }
            NSUInteger count = cache.count;
            if (count != 1) {
                STFail(@"Cache count should be 1");
                [self notify:SenAsyncTestCaseStatusFailed];
            }

            [cache reset];

            if (cache.count !=0) {
                STFail(@"Cache count should be 0");
                [self notify:SenAsyncTestCaseStatusFailed];
            }

            [self notify:SenAsyncTestCaseStatusSucceeded];
        }
    } failure:^(NSError *error) {
        STFail(@"An error should not have occured while attempting to load remote object http://damienglancy.ie/blogimages/weather1.png");
        [self notify:SenAsyncTestCaseStatusFailed];
    }];

    [self waitForStatus:SenAsyncTestCaseStatusSucceeded timeout:STANDARD_TIMEOUT_IN_SECS];
}

- (void)testObjectCacheLoadsAnValidRemoteObjectAndPlacesItInCache
{
    DGObjectCache *cache = [DGObjectCache cache];
    [cache reset];

    [cache objectWithURL:[NSURL URLWithString:@"http://damienglancy.ie/blogimages/weather1.png"] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
        STAssertNotNil(object, @"An object should have been returned.");
        if (!object) {
            [self notify:SenAsyncTestCaseStatusFailed];
        } else {
            if (source != ObjectLoadSourceNetwork) {
                STFail(@"Object should have been loaded from network and not cache");
                [self notify:SenAsyncTestCaseStatusFailed];
            }
            NSUInteger count = cache.count;
            if (count != 1) {
                STFail(@"Cache count should be 1");
                [self notify:SenAsyncTestCaseStatusFailed];
            }

            [self notify:SenAsyncTestCaseStatusSucceeded];
        }
    } failure:^(NSError *error) {
        STFail(@"An error should not have occured while attempting to load remote object http://damienglancy.ie/blogimages/weather1.png");
        [self notify:SenAsyncTestCaseStatusFailed];
    }];

    [self waitForStatus:SenAsyncTestCaseStatusSucceeded timeout:STANDARD_TIMEOUT_IN_SECS];
}

- (void)testObjectCacheLoadsAnValidRemoteObjectAndPlacesItInCacheAndThenReturnsItFromCacheOnSubsequentRequests
{
    __block DGObjectCache *cache = [DGObjectCache cache];
    [cache reset];

    [cache objectWithURL:[NSURL URLWithString:@"http://damienglancy.ie/blogimages/weather1.png"] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
        STAssertNotNil(object, @"An object should have been returned.");
        if (!object) {
            [self notify:SenAsyncTestCaseStatusFailed];
        } else {
            if (source != ObjectLoadSourceNetwork) {
                STFail(@"Object should have been loaded from network and not cache");
                [self notify:SenAsyncTestCaseStatusFailed];
            }
            NSUInteger count = cache.count;
            if (count != 1) {
                STFail(@"Cache count should be 1");
                [self notify:SenAsyncTestCaseStatusFailed];
            }

            [cache objectWithURL:[NSURL URLWithString:@"http://damienglancy.ie/blogimages/weather1.png"] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
                if (source != ObjectLoadSourceCache) {
                    STFail(@"Object should have been loaded from cache and not network");
                    [self notify:SenAsyncTestCaseStatusFailed];
                }

                [self notify:SenAsyncTestCaseStatusSucceeded];
            } failure:^(NSError *error) {
                STFail(@"An error should not have occured while attempting to load remote object http://damienglancy.ie/blogimages/weather1.png");
                [self notify:SenAsyncTestCaseStatusFailed];
            }];
        }
    } failure:^(NSError *error) {
        STFail(@"An error should not have occured while attempting to load remote object http://damienglancy.ie/blogimages/weather1.png");
        [self notify:SenAsyncTestCaseStatusFailed];
    }];

    [self waitForStatus:SenAsyncTestCaseStatusSucceeded timeout:STANDARD_TIMEOUT_IN_SECS];
}

- (void)testObjectCacheLoadsMultipleValidRemoteObjectsAndPlacesThemInCache
{
    DGObjectCache *cache = [DGObjectCache cache];

    NSUInteger TARGET_INSERTS = 10;

    for (NSUInteger i=0; i < TARGET_INSERTS; i++) {
        NSString *url = [NSString stringWithFormat:@"%@?%@", @"http://damienglancy.ie/blogimages/weather1.png",[NSProcessInfo processInfo].globallyUniqueString];

        [cache objectWithURL:[NSURL URLWithString:url] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
            STAssertNotNil(object, @"An object should have been returned.");
            if (!object) {
                [self notify:SenAsyncTestCaseStatusFailed];
            } else {
                if (source != ObjectLoadSourceNetwork) {
                    STFail(@"Object should have been loaded from network and not cache");
                    [self notify:SenAsyncTestCaseStatusFailed];
                }

                if (i == TARGET_INSERTS-1) {
                    [self notify:SenAsyncTestCaseStatusSucceeded];
                }
            }
        } failure:^(NSError *error) {
            STFail(@"An error should not have occured while attempting to load remote object http://damienglancy.ie/blogimages/weather1.png");
            [self notify:SenAsyncTestCaseStatusFailed];
        }];
    }

    [self waitForStatus:SenAsyncTestCaseStatusSucceeded timeout:STANDARD_TIMEOUT_IN_SECS*6];
}

- (void)testObjectCacheDeleteExistingResource
{
    DGObjectCache *cache = [DGObjectCache cache];

    [cache objectWithURL:[NSURL URLWithString:@"http://damienglancy.ie/blogimages/weather1.png"] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
        STAssertNotNil(object, @"An object should have been returned.");
        if (!object) {
            [self notify:SenAsyncTestCaseStatusFailed];
        } else {
            if (source != ObjectLoadSourceNetwork) {
                STFail(@"Object should have been loaded from network and not cache");
                [self notify:SenAsyncTestCaseStatusFailed];
            }
            NSUInteger count = cache.count;
            if (count != 1) {
                STFail(@"Cache count should be 1");
                [self notify:SenAsyncTestCaseStatusFailed];
            }

            [cache removeObjectWithURL:[NSURL URLWithString:@"http://damienglancy.ie/blogimages/weather1.png"] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
                NSUInteger count = cache.count;
                if (count != 0) {
                    STFail(@"Cache count should be 0");
                    [self notify:SenAsyncTestCaseStatusFailed];
                }
                [self notify:SenAsyncTestCaseStatusSucceeded];
            } failure:^(NSError *error) {
                [self notify:SenAsyncTestCaseStatusFailed];
            }];
        }
    } failure:^(NSError *error) {
        STFail(@"An error should not have occured while attempting to load remote object http://damienglancy.ie/blogimages/weather1.png");
        [self notify:SenAsyncTestCaseStatusFailed];
    }];
    
    [self waitForStatus:SenAsyncTestCaseStatusSucceeded timeout:STANDARD_TIMEOUT_IN_SECS];
}

- (void)testObjectCacheHandlesCapacityLimitsCorrectly
{
    DGObjectCache *cache = [DGObjectCache cacheWithCapacity:2];

    NSUInteger TARGET_INSERTS = 10;

    for (NSUInteger i=0; i < TARGET_INSERTS; i++) {
        NSString *url = [NSString stringWithFormat:@"%@?%@", @"http://damienglancy.ie/blogimages/weather1.png",[NSProcessInfo processInfo].globallyUniqueString];

        [cache objectWithURL:[NSURL URLWithString:url] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
            STAssertNotNil(object, @"An object should have been returned.");
            if (!object) {
                [self notify:SenAsyncTestCaseStatusFailed];
            } else {
                if (source != ObjectLoadSourceNetwork) {
                    STFail(@"Object should have been loaded from network and not cache");
                    [self notify:SenAsyncTestCaseStatusFailed];
                }

                if (i == TARGET_INSERTS-1) {
                    [self notify:SenAsyncTestCaseStatusSucceeded];
                }
            }
        } failure:^(NSError *error) {
            STFail(@"An error should not have occured while attempting to load remote object http://damienglancy.ie/blogimages/weather1.png");
            [self notify:SenAsyncTestCaseStatusFailed];
        }];
    }

    [self waitForStatus:SenAsyncTestCaseStatusSucceeded timeout:STANDARD_TIMEOUT_IN_SECS*6];
}

@end
