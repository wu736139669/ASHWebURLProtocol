//
//  ASHWebNSURLProtocol.m
//  ASHWebURLProtocol
//
//  Created by xmfish on 16/11/16.
//  Copyright © 2016年 ash. All rights reserved.
//

#import "ASHWebNSURLProtocol.h"

@interface ASHCachedData : NSObject<NSCoding>
@property (nonatomic, readwrite, strong) NSData *data;
@property (nonatomic, readwrite, strong) NSURLResponse *response;
@end

static NSString *const kDataKey = @"data";
static NSString *const kResponseKey = @"response";
static NSString *const kHTTPHeaderField = @"ASH-WebView-Caching";
@implementation ASHCachedData

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[self data] forKey:kDataKey];
    [aCoder encodeObject:[self response] forKey:kResponseKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self != nil) {
        [self setData:[aDecoder decodeObjectForKey:kDataKey]];
        [self setResponse:[aDecoder decodeObjectForKey:kResponseKey]];
    }
    
    return self;
}
@end

@interface ASHWebNSURLProtocol()
@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic, strong) NSURLSession* session;
@property (nonatomic, readwrite, strong) NSMutableData *data;
@property (nonatomic, readwrite, strong) NSURLResponse *response;
@end


@implementation ASHWebNSURLProtocol

- (NSString *)cachePathForRequest:(NSURLRequest *)aRequest
{
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileName = [NSString stringWithFormat:@"%lu",[[[aRequest URL] absoluteString] hash]];
    
    return [cachesPath stringByAppendingPathComponent:fileName];
}

- (void)appendData:(NSData *)newData
{
    if ([self data] == nil) {
        [self setData:[newData mutableCopy]];
    }
    else {
        [[self data] appendData:newData];
    }
}

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

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest*)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}
- (void)startLoading
{
    
    
    NSString *cachesPath = [self cachePathForRequest:[self request]];
    ASHCachedData *cache = [NSKeyedUnarchiver unarchiveObjectWithFile:cachesPath];
    
    if (cache) {
        NSData *data = cache.data;
        
        [[self client] URLProtocol:self didReceiveResponse:cache.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [[self client] URLProtocol:self didLoadData:data];
        [[self client] URLProtocolDidFinishLoading:self];
//        return;
    }
    
    
    NSMutableURLRequest *newRequest = [self.request mutableCopy];

    [newRequest setValue:@"" forHTTPHeaderField:kHTTPHeaderField];
    [newRequest setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    
    self.connection = [NSURLConnection connectionWithRequest:newRequest
                                                                delegate:self];
    
}
- (void)stopLoading
{
//    [self.connection cancel];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self setResponse:response];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    [self appendData:data];
    
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
    
    NSString *cachesPath = [self cachePathForRequest:[self request]];
    
    
    
    ASHCachedData *cache = [ASHCachedData new];
    cache.data = [self data];
    cache.response = [self response];
    
    [NSKeyedArchiver archiveRootObject:cache toFile:cachesPath];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

@end
