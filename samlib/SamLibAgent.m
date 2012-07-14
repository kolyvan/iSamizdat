//
//  SamLibAgent.m
//  samlib
//
//  Created by Kolyvan on 07.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "SamLibAgent.h"
#import "SamLibStorage.h"
#import "KxUtils.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "AFHTTPClient+Kolyvan.h"
#import "AFHTTPRequestOperation.h"
#import "DDLog.h"

extern int ddLogLevel;

#ifdef DEBUG
//#define _DEVELOPMENT_MODE_
#endif

//#pragma mark - defaults


static NSString * samlibURL()
{
    static NSString * url = nil;
    
    if (!url) {        
        url = KX_RETAIN([[NSUserDefaults standardUserDefaults] stringForKey:@"samlib"]);
        if (!url)
            url = @"samlib.ru";
    }       
    
    return url;
}

static NSString * settingsPath()
{
    static NSString * path = nil;
    
    if (!path) {
       
#ifdef _DEVELOPMENT_MODE_            
        path = [@"~/tmp/samlib/settings" stringByExpandingTildeInPath];
#else
        path = KX_RETAIN([KxUtils.privateDataPath() stringByAppendingPathComponent: @"settings"]);
#endif        
    }
    
    return path;    
}

static NSMutableDictionary * _settings(BOOL save)
{   
    static NSMutableDictionary * dict = nil;
    static NSString *digest = nil;
    
    if (save) {
        
        if (dict.nonEmpty) {
        
            NSString *md5 = [[dict description] md5];
        
            if (![md5 isEqualToString: digest]) {
                
                KX_RELEASE(digest);
                digest = KX_RETAIN(md5);
                SamLibStorage.saveDictionary(dict, settingsPath()); 
                
                DDLogCVerbose(@"save settings: %ld", dict.count);
            }
        }
    }
    else {
        
        if (!dict) {
                        
            NSMutableDictionary *d;
            d = (NSMutableDictionary *)SamLibStorage.loadDictionaryEx(settingsPath(), NO);
            
            if (d) {
                digest = KX_RETAIN([[d description] md5]);
                DDLogCVerbose(@"load settings: %ld", d.count);
            }
            else
                d = [NSMutableDictionary dictionary];
            
            dict = KX_RETAIN(d);
        }
    }
    
    return dict;
}

static NSMutableDictionary * settings()
{       
    return _settings(NO);
}

static void saveSettings()
{
    _settings(YES);
}


static id getSettings(NSString *key, id defaultValue)
{
    return [settings() get:key orElse:defaultValue];
}

static void setSettings(NSString *key, id value,  id defaultValue)
{
    id current = getSettings(key, defaultValue);
    
    if (![current isEqual: value]) {
        
        if (!value ||
            [value isEqual: defaultValue]) {
            
            [settings() removeObjectForKey:key];
        }
        else {
           
            [settings() update: key value: value];
        }    
    };
}

static BOOL settingsBool(NSString *key, BOOL defaultValue)
{
    return [getSettings(key, [NSNumber numberWithBool:defaultValue]) boolValue];
}

static void setSettingsBool(NSString *key, BOOL value, BOOL defaultValue)
{
    setSettings(key, 
                [NSNumber numberWithBool:value], 
                [NSNumber numberWithBool:defaultValue]);
}

static NSInteger settingsInt(NSString *key, NSInteger defaultValue)
{
    return [getSettings(key, [NSNumber numberWithInteger:defaultValue]) integerValue];
}

static void setSettingsInt(NSString *key, NSInteger value, NSInteger defaultValue)
{
    setSettings(key, 
                [NSNumber numberWithInteger:value], 
                [NSNumber numberWithInteger:defaultValue]);
}

static CGFloat settingsFloat(NSString *key, CGFloat defaultValue)
{
    return [getSettings(key, [NSNumber numberWithFloat:defaultValue]) floatValue];    
}

static void setSettingsFloat(NSString *key, CGFloat value, CGFloat defaultValue)
{
    setSettings(key, 
                [NSNumber numberWithFloat:value], 
                [NSNumber numberWithFloat:defaultValue]);    
}

static NSString * settingsString(NSString *key,  NSString * defaultValue)
{
    return getSettings(key, defaultValue);
}

static void setSettingsString(NSString *key, NSString *value, NSString *defaultValue)
{
    setSettings(key, value, defaultValue);
}

//#pragma mark - fetching

static AFHTTPClient * httpClient(BOOL cleanup)
{
    static AFHTTPClient *client = nil;
    
    if (cleanup) 
    {
        [client cancelAll];
        KX_RELEASE(client);
        client = nil;
    }
    else if (!client)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            //NSMutableIndexSet *codes = [NSMutableIndexSet indexSet];
            //[codes addIndex:302];
            //[codes addIndex:304];            
            NSIndexSet *codes = [NSIndexSet indexSetWithIndex:304];            
            [[AFHTTPRequestOperation class] addAcceptableStatusCodes: codes];
            
            //NSSet *contens = [NSSet setWithObject: @"text/html"];    
            //[[AFHTTPRequestOperation class] addAcceptableContentTypes: contens];
        });
        
        
        NSString * url = [@"http://" stringByAppendingString: samlibURL()];
        
        client = [[AFHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:url]];
        
        [client setDefaultHeader:@"Accept-Language" value:@"ru-RU, ru, en-US;q=0.8"]; 
        
        //@"samizdatSpider/0.1, (unknown)"; 
        [client setDefaultHeader:@"User-Agent" 
                           value:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:12.0) Gecko/20100101 Firefox/12.0"]; 
        
        [client setDefaultHeader:@"Pragma" value:@"no-cache"];
        [client setDefaultHeader:@"Cache-Control" value:@"no-cache, max-age=0"];
    }
    
    return client;    
}

static void logResponse(NSHTTPURLResponse * hr)
{
    if (LOG_INFO) {
        DDLogCInfo(@"%ld %@", hr.statusCode, hr.URL);

        if (LOG_VERBOSE) {
            NSDictionary * d = hr.allHeaderFields;
            [d enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                DDLogCVerbose(@"  %@: %@", key, obj);
            }];
        }
    }
}

static void logRequest(NSURLRequest * req)
{
    if (LOG_INFO) {
        DDLogCInfo(@"%@ %@", req.HTTPMethod, req.URL);
        
        if (LOG_VERBOSE) {
            NSDictionary * d = req.allHTTPHeaderFields;
            [d enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                DDLogCVerbose(@"  %@: %@", key, obj);
            }];
        }
    }
}

static void handleSuccess(AFHTTPRequestOperation *operation, 
                          id responseObject, 
                          AsyncResultBlock block)
{
    NSHTTPURLResponse * response = (NSHTTPURLResponse *)operation.response;
    
    logRequest(operation.request);
    logResponse(response);
    
    if (response.statusCode == 304) {
        block(SamLibStatusNotModifed, nil, nil);
    } else  {
        
        NSString *lastModified = [response.allHeaderFields objectForKey:@"Last-Modified"];
        block(SamLibStatusSuccess, operation.responseString, lastModified);
    }
}

static void handleFailure(AFHTTPRequestOperation *operation, 
                          NSError *error,
                          AsyncResultBlock block)
{
    NSHTTPURLResponse * response = (NSHTTPURLResponse *)operation.response;
    
    logRequest(operation.request);
    logResponse(response);
    
    NSString *message = nil;
    
    if (response)
        message = [NSHTTPURLResponse localizedStringForStatusCode: response.statusCode];                  
    else
        message = [error localizedDescription];
    
    block(SamLibStatusFailure, message, nil);      
}

static void fetchData(NSString *path, 
                      NSString *lastModified, 
                      BOOL handleCookies,
                      NSString *referer, 
                      NSDictionary * parameters,
                      AsyncResultBlock block,
                      AsyncProgressBlock progress)
{
    AFHTTPClient *client = httpClient(NO);
    
    [client getPath: path
         ifModified: lastModified
      handleCookies: handleCookies
            referer: referer
         parameters: parameters
            success:^(AFHTTPRequestOperation *operation, id responseObject) {                  
                
                handleSuccess(operation, responseObject, block);
                
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
                handleFailure(operation, error, block);
                
            }
           progress:progress];
}

static void postData(NSString *path, 
                     NSString *referer, 
                     NSDictionary * parameters,
                     BOOL redirect,
                     AsyncResultBlock block)
{
    AFHTTPClient *client = httpClient(NO);
    
    NSStringEncoding stringEncoding = client.stringEncoding;
    client.stringEncoding = NSWindowsCP1251StringEncoding;

    [client postPath:path
             referer:referer             
          parameters:parameters
            redirect:redirect
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 
                 handleSuccess(operation, responseObject, block);
             } 
             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 
                handleFailure(operation, error, block);
                 
             }];
    
    client.stringEncoding = stringEncoding; 
}

static void cancelAll()
{
    AFHTTPClient *client = httpClient(NO);
    [client cancelAll];
}

//

static void initialize ()
{   
}

static void cleanup ()
{
    httpClient(YES);    // stop and release client
    _settings(YES);     // save settings
}


SamLibAgent_t SamLibAgent = {
    
    initialize,
    cleanup,
    
    samlibURL,
    
    settings,
    saveSettings,
    settingsBool,
    setSettingsBool,    
    settingsInt,
    setSettingsInt,
    settingsFloat,
    setSettingsFloat,    
    settingsString,
    setSettingsString,
    
    fetchData,
    postData,
    cancelAll,    
  
};