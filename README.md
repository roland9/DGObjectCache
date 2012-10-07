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

Use the cache like this:

```objective-c

    //init the cache (singleton)
	DGObjectCache *cache = [DGObjectCache cache];
	
	//load a resource
	[cache objectWithURL:[NSURL URLWithString:@"http://damienglancy.ie/blogimages/weather1.png"] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
		//Notes:
		//data = is the contents of your URL resource.
		//response =  contains the http response from your network request, if the cache had to retrieve the resource from the network.
		//resource is nil if it was delivered from the cache
		//source indicates if the resource was delivered from the network or the cache
	        
	} failure:^(NSError *error) {
		//an error occured
	}];
	
```

You can reset the cache at any time:

```objective-c

	DGObjectCache *cache = [DGObjectCache cache];
	[cache reset];
```

You can remove a specific resource from the:

```objective-c

	DGObjectCache *cache = [DGObjectCache cache];
	
	//remove a resource from the cache
	[cache removeObjectWithURL:[NSURL URLWithString:@"http://damienglancy.ie/blogimages/weather1.png"] success:^(NSData *object, NSURLResponse *response, ObjectLoadSource source) {
		//resource removed
	} failure:^(NSError *error) {
		//an error occured
	}];
```

