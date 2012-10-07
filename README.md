DGObjectCache
=============

An objective-c based URL object cache, backed by Core Data. This is a network aware pass-thru cache, meaning that you make a request for a URL-based resource to the cache. If the cache has the resource it will deliver it from within its cache. If the cache does not have the resource, then it will fetch it for you, insert into the cache and hand the resource over to you. Subsequent requests for that resource will be delivered from the cache. 

This cache is designed to cache resources for a relatively long time (between application restarts) and is optimized for that use case. It is not as fast as a pure in-memory cache.

Features
--------

* High-performance core-data backed cache, utilizing the memory efficiencies of using `NSManagedObjects`.
* Configurable cache-size.
* Asynchronous, block-based API.
* Small and simple code-base: Two class files, two matching headers and a Core Data model file.
* Monitor the cache performance, cache size, hits, misses, etc.


Installation
------------

1. Copy the files from `ObjectCache` into your project.
2. Make sure that you are linking against the `CoreData.framework`.

Using the cache
---------------

Init the cache by:

```objc

    //init the cache
	DGObjectCache *cache = [DGObjectCache cache];
	
	//load a resource
	[cache objectWithURL:[NSURL URLWithString:@"http://damienglancy.ie/blogimages/weather1.png"] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
	       
	        
	} failure:^(NSError *error) {
	        STFail(@"An error should not have occured while attempting to load remote object http://damienglancy.ie/blogimages/weather1.png");
	        [self notify:SenAsyncTestCaseStatusFailed];
	}];
	
```
