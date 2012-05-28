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
    NSString * (*authorsPath)();
    NSString * (*textsPath)();    
    NSString * (*commentsPath)();
    NSString * (*indexPath)();    
    
    NSMutableDictionary * (*settings)();
   
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
                     AsyncResultBlock block);
    
    void (*cancelAll)();    
       
    NSArray* (*loadAuthors)();
    void (*removeAuthor)(NSString *path);
    
    
} SamLibAgent_t;

extern SamLibAgent_t SamLibAgent;