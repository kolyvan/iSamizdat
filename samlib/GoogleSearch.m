//
//  GoogleSearch.m
//  samlib
//
//  Created by Kolyvan on 17.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "GoogleSearch.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "AFHTTPClient+Kolyvan.h"
#import "AFHTTPRequestOperation.h"
#import "JSONKit.h"
#import "DDLog.h"
#import "SamLib.h"

extern int ddLogLevel;

/*
 https://developers.google.com/web-search/docs/?hl=ru-RU#fonje
 http://www.googleguide.com/advanced_operators.html#allinanchor
 
 http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=site:samlib.ru/k%20inurl:indexdate.shtml&start=0
  
 query samples:
    site:samlib.ru/k inurl:indexdate.shtml
    site:samlib.ru/i intitle:Иванов inurl:indexdate.shtml 
    site:samlib.ru/s intitle:Смирнов intitle:Василий inurl:indexdate.shtml 
*/

typedef void (^GetGoogleSearchResult)(GoogleSearchStatus status, NSString *details, NSDictionary *data);

static void getGoogleSearch(AFHTTPClient *client, NSDictionary *parameters, GetGoogleSearchResult block)
{ 
    [client getPath: @"ajax/services/search/web"
       ifModified: nil
    handleCookies: NO
          referer: nil
       parameters: parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {                  
              
              NSHTTPURLResponse * response = (NSHTTPURLResponse *)operation.response;              
              DDLogCInfo(@"%ld %@", response.statusCode, response.URL);
              
              NSError *error;
              NSDictionary *json;
              json =[operation.responseString objectFromJSONStringWithParseOptions:JKParseOptionNone 
                                                                             error:&error];
              if (json) {
                  
                  NSInteger status = [[json get: @"responseStatus"] integerValue];
                  if (status == 200) {
                      
                      NSDictionary *data = [json get: @"responseData"];
                      block(GoogleSearchStatusSuccess, nil, data);                      
                      
                  } else {
                      
                      NSString * details = [json get: @"responseDetails"];                      
                      block(GoogleSearchStatusResponseFailure, KxUtils.format(@"%d(%@)", status, details), nil);
                  }
                  
                  
              } else {
                      
                  NSString * details = KxUtils.completeErrorMessage(error);
                  block(GoogleSearchStatusJSONFailure, details, nil);
              }
             
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
              NSHTTPURLResponse * response = (NSHTTPURLResponse *)operation.response;
              
              DDLogCWarn(@"%ld %@", response.statusCode, response.URL);
              
              NSString *message = nil;
              
              if (response)
                  message = [NSHTTPURLResponse localizedStringForStatusCode: response.statusCode];                  
              else
                  message = [error localizedDescription];
           
              block(GoogleSearchStatusHTTPFailure, message, nil);
              
          }
         progress:nil];
}

////

@interface GoogleSearch() {
    AFHTTPClient *_client;
}
@property (readonly) BOOL canceled;

@end

@implementation GoogleSearch

@synthesize canceled = _canceled;

- (id) init
{
    self = [super init];
    if (self) {
        _client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://ajax.googleapis.com/"]];
    }
    return self;
}

- (void) dealloc
{
    DDLogInfo(@"%@ dealloc", [self class]);
    
    [self cancel];
    KX_SUPER_DEALLOC();
}

+ (id) search: (NSString *)query 
          block: (GoogleSearchResult) block
{
    GoogleSearch *p = [[GoogleSearch alloc] init];
    [p search:query block:block];
    return  KX_AUTORELEASE(p);
}

- (void) cancel
{
    _canceled = YES;
    [_client cancelAll];
    KX_RELEASE(_client);
    _client = nil;
}

- (void) search: (NSString *)query 
          block: (GoogleSearchResult) block;

{   
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:4];
    
    [parameters update:@"v" value:@"1.0"];
    [parameters update:@"rsz" value:@"8"];
    [parameters update:@"start" value:@"0"];
    [parameters update:@"q" value:query];
    
    KX_WEAK GoogleSearch *this = self;
    
    getGoogleSearch(_client, 
                    parameters, 
                    ^(GoogleSearchStatus status, NSString *details, NSDictionary *data) {
                        
                        if (status == GoogleSearchStatusSuccess) {
                                                                                    
                            NSMutableArray *results = [[data get:@"results"] mutableCopy];                        
                            NSDictionary *cursor = [data get:@"cursor"];
                            NSArray *pages = [cursor get:@"pages"];
                                                        
                            // google doesn't like simultaneous requests!
                            
                            if (pages.count > 1 && this && !this.canceled) {
                                
                                [this moreSearch: parameters 
                                           pages: pages.tail 
                                         results: results 
                                           block: block];
                            } else {                                
                                
                                block(GoogleSearchStatusSuccess, nil, results);                            
                            }
                            
                        } else {
                            
                            block(status, details, nil);                                        
                        }       
                    });
}

- (void) moreSearch: (NSDictionary *)parameters 
              pages: (NSArray *)  pages
            results: (NSMutableArray *)results
              block: (GoogleSearchResult) block
{
    NSDictionary *page = pages.first;
    NSMutableDictionary *parameters_ = [parameters mutableCopy];    
    NSString *start = [page get:@"start"];
    [parameters_ update:@"start" value:start]; 
    
    KX_WEAK GoogleSearch *this = self;
    
    getGoogleSearch(_client, 
                    parameters_, 
                    ^(GoogleSearchStatus status, NSString *details, NSDictionary *data) {
                        
                        if (status == GoogleSearchStatusSuccess) {
                            
                            NSArray *r = [data get:@"results"];   
                            
                            [results appendAll:r];
                            
                            if (pages.count > 1 && this && !this.canceled)
                                
                                [this moreSearch: parameters 
                                           pages: pages.tail 
                                         results: results 
                                           block: block];

                            else
                                block(GoogleSearchStatusSuccess, nil, results);            
                            
                        } else {
                            
                            DDLogCWarn(@"googleSearch failure: %d %@", status, details);            
                            
                            // at least one request has been received successfully            
                            block(GoogleSearchStatusSuccess, nil, results); 
                        }
                    });    
}

@end