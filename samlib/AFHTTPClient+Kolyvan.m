//
//  AFHTTPClient+Kolyvan.m
//  samlib
//
//  Created by Kolyvan on 07.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "AFHTTPClient+Kolyvan.h"
#import "AFURLConnectionOperation.h"
#import "AFHTTPRequestOperation.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface AFHTTPRequestOperation_NoRedirect : AFHTTPRequestOperation

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse;

@end

@implementation AFHTTPRequestOperation_NoRedirect

+ (NSIndexSet *)acceptableStatusCodes {
    NSMutableIndexSet * mis = [[AFHTTPRequestOperation acceptableStatusCodes] mutableCopy];
    [mis addIndex:302];
    return [mis autorelease];
}

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse
{   
    if (redirectResponse) {
        
        DDLogInfo(@"stop redirect %@ to %@", redirectResponse.URL.relativePath, request.URL.relativePath);        
        //if ([redirectResponse.URL.relativePath isEqualToString:@"/cgi-bin/votecounter"])
        return nil;
    }
    
    return request;
}

@end

////

@implementation AFHTTPClient (Kolyvan)

- (void) getPath:(NSString *)path
      ifModified:(NSString *)ifModified
   handleCookies:(BOOL) handleCookies
         referer:(NSString *)referer 
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure 
{
    [self getPath:path 
       ifModified:ifModified 
    handleCookies:handleCookies 
          referer:referer 
       parameters:nil
          success:success 
          failure:failure
         progress:nil];
}

- (void) getPath:(NSString *)path
      ifModified:(NSString *)ifModified
   handleCookies:(BOOL) handleCookies
         referer:(NSString *)referer
      parameters:(NSDictionary *)parameters 
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure 
{
    [self getPath:path 
       ifModified:ifModified 
    handleCookies:handleCookies 
          referer:referer 
       parameters:nil
          success:success 
          failure:failure 
         progress:nil];
}

- (void) getPath:(NSString *)path
      ifModified:(NSString *)ifModified
   handleCookies:(BOOL) handleCookies
         referer:(NSString *)referer
      parameters:(NSDictionary *)parameters 
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure 
        progress:(void (^)(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
{
    
    NSAssert(path != nil && path.length > 0, @"empty path");
    
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:parameters];
    
    [request setHTTPShouldHandleCookies: handleCookies];            
    
    if (referer)
        [request addValue:referer forHTTPHeaderField:@"Referer"];
    
    if (ifModified) {
        [request setCachePolicy: NSURLRequestReloadIgnoringLocalCacheData];        
        [request addValue:ifModified forHTTPHeaderField:@"If-Modified-Since"];
    }
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];     
    
    if (progress) {
        operation.downloadProgressBlock = progress;
    }
    
    [self enqueueHTTPRequestOperation:operation];
}

- (void)postPath:(NSString *)path
         referer:(NSString *)referer
      parameters:(NSDictionary *)parameters 
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{    
    [self postPath:path 
           referer:referer 
        parameters:parameters 
          redirect:YES 
           success: success 
           failure:failure];
}

- (void)postPath:(NSString *)path
         referer:(NSString *)referer
      parameters:(NSDictionary *)parameters 
        redirect:(BOOL)redirect
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{    
    NSAssert(path != nil && path.length > 0, @"empty path");
    
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters];
    
    [request setHTTPShouldHandleCookies: YES];            
    
    if (referer)
        [request addValue:referer forHTTPHeaderField:@"Referer"];
    
    // this is for samlib.ru site 
    // unfortunately theirs coders cannot into content-type charset
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];    
    
	//AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    
    AFHTTPRequestOperation *operation;       
    if (redirect) {
        operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    } else {
        operation = [[[AFHTTPRequestOperation_NoRedirect alloc] initWithRequest:request] autorelease];
        [operation setCompletionBlockWithSuccess:success failure:failure];
    }
    
    [self enqueueHTTPRequestOperation:operation];    
}


- (void) cancelAll 
{
    for (NSOperation *operation in [self.operationQueue operations]) {
        if ([operation isKindOfClass:[AFHTTPRequestOperation class]]) {
            [operation cancel];
        }
    }
}

@end
