//
//  SamLibAgent.h
//  samlib
//
//  Created by Kolyvan on 07.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import <Foundation/Foundation.h>

#import "SamLib.h"


typedef void (^AsyncResultBlock)(SamLibStatus status, NSString *data, NSString *lastModified);
typedef void (^AsyncProgressBlock)(NSInteger bytes, long long totalBytes, long long totalBytesExpected);

typedef struct {

    void (*initialize)();
    void (*cleanup)();
        
    NSString * (*samlibURL)();        
    
    NSMutableDictionary * (*settings)();
    void (*saveSettings)();
    
    BOOL (*settingsBool)(NSString *key, BOOL defaultValue);
    void (*setSettingsBool)(NSString *key, BOOL value, BOOL defaultValue);
    NSInteger (*settingsInt)(NSString *key, NSInteger defaultValue);
    void (*setSettingsInt)(NSString *key, NSInteger value, NSInteger defaultValue);
    NSString * (*settingsString)(NSString *key,  NSString * defaultValue);
    void (*setSettingsString)(NSString *key, NSString *value, NSString *defaultValue);
   
    void (*fetchData)(NSString *path, 
                      NSString *lastModified, 
                      BOOL handleCookies,
                      NSString *referer,                            
                      NSDictionary * parameters,                      
                      AsyncResultBlock block,
                      AsyncProgressBlock progress);
    
    void (*postData)(NSString *path, 
                     NSString *referer,                  
                     NSDictionary * parameters,
                     BOOL redirect,                         
                     AsyncResultBlock block);
    
    void (*cancelAll)();
    
} SamLibAgent_t;

extern SamLibAgent_t SamLibAgent;