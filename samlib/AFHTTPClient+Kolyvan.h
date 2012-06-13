//
//  AFHTTPClient+Kolyvan.h
//  samlib
//
//  Created by Kolyvan on 07.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

@interface AFHTTPClient (Kolyvan)


- (void) getPath:(NSString *)path
      ifModified:(NSString *)ifModified
   handleCookies:(BOOL) handleCookies
         referer:(NSString *)referer
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure ;

- (void) getPath:(NSString *)path
      ifModified:(NSString *)ifModified
   handleCookies:(BOOL) handleCookies
         referer:(NSString *)referer
      parameters:(NSDictionary *)parameters 
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure ;


- (void) getPath:(NSString *)path
      ifModified:(NSString *)ifModified
   handleCookies:(BOOL) handleCookies
         referer:(NSString *)referer
      parameters:(NSDictionary *)parameters 
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure 
        progress:(void (^)(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress;

- (void)postPath:(NSString *)path
          referer:(NSString *)referer
       parameters:(NSDictionary *)parameters 
          success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;


- (void)postPath:(NSString *)path
         referer:(NSString *)referer
      parameters:(NSDictionary *)parameters 
        redirect:(BOOL)redirect  
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;



- (void) cancelAll;

@end
