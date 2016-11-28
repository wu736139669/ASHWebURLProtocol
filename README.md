# ASHWebURLProtocol
iOS WebView缓存
###首先继承 `NSURLProtocol`

```
+(BOOL)canInitWithRequest:(NSURLRequest *)request
{
    
    ///通过UA 来判断是否UIWebView发起的请求
    NSString* UA = [request valueForHTTPHeaderField:@"User-Agent"];
    if ([UA containsString:@" AppleWebKit/"] == NO) {
        return NO;
    }
    
    if ([request valueForHTTPHeaderField:kHTTPHeaderField]) {
        return NO;
    }
    return YES;
}
```
`NSString* UA = [request valueForHTTPHeaderField:@"User-Agent"];`
中可以判断是否是`WebView`发出的请求。
当判断是`WebView`的时候才进行处理。

```
- (void)startLoading
{
    
    
    NSString *cachesPath = [self cachePathForRequest:[self request]];
    ASHCachedData *cache = [NSKeyedUnarchiver unarchiveObjectWithFile:cachesPath];
    
    //使用缓存。
    if (cache) {
        NSData *data = cache.data;
        
        [[self client] URLProtocol:self didReceiveResponse:cache.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [[self client] URLProtocol:self didLoadData:data];
        [[self client] URLProtocolDidFinishLoading:self];
        //        return;
    }
    
    //重新请求。
    NSMutableURLRequest *newRequest = [self.request mutableCopy];

    [newRequest setValue:@"" forHTTPHeaderField:kHTTPHeaderField];
    [newRequest setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    
    self.connection = [NSURLConnection connectionWithRequest:newRequest
                                                                delegate:self];
    
}
```
###上面是主要的代码，先使用了缓存，然后再去重新请求，这样就会刷新请求数据.


```
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
    
    NSString *cachesPath = [self cachePathForRequest:[self request]];
    
    
    
    ASHCachedData *cache = [ASHCachedData new];
    cache.data = [self data];
    cache.response = [self response];
    
    [NSKeyedArchiver archiveRootObject:cache toFile:cachesPath];
}
```

###
最后一段就是对内容进行保存，当然也可以根据后缀把图片单独用`SDWebImage`保存，可以和原生代码里面的图片共用缓存。


###最后还需要注册一下 在 `AppDelegate` 中

```
[NSURLProtocol  registerClass:[ASHWebNSURLProtocol class]];
```