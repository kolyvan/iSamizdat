//
//  SamLib.h
//  samlib
//
//  Created by Kolyvan on 08.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 
 

#import <Foundation/Foundation.h>
#import "KxArc.h"

typedef enum {
    
    SamLibStatusSuccess,
    SamLibStatusFailure,
    SamLibStatusNotModifed,    
    
} SamLibStatus;

////

@class SamLibAuthor;
@class SamLibText;

////

extern NSString * getStringFromDict(NSDictionary *dict, NSString *name, NSString *path);
extern NSDate * getDateFromDict(NSDictionary * dict, NSString *name, NSString *path);
extern NSHTTPCookie * searchSamLibCookie(NSString *name);
extern NSHTTPCookie * deleteSamLibCookie(NSString *name);
extern NSDictionary * loadDictionary(NSString *filepath);
extern NSDictionary * loadDictionaryEx(NSString *filepath, BOOL immutable);
extern BOOL saveDictionary(NSDictionary *dict, NSString * filepath);
extern BOOL saveObject(id obj, NSString * filepath);
extern id loadObject(NSString *filepath, BOOL immutable);
extern int levenshteinDistance(unichar* s1, int n, unichar *s2, int m);
extern int levenshteinDistanceNS(NSString* s1, unichar *s2, int m);

////

@interface SamLibBase : NSObject {

@protected    
    NSString * _path;
    NSDate * _timestamp;
}

@property (readonly, nonatomic) NSString *path; 
@property (readwrite, nonatomic, KX_PROP_STRONG) NSDate *timestamp;
@property (readonly, nonatomic) BOOL changed;

@property (readonly) NSString * url;
@property (readonly) NSString * relativeUrl;

@property (readonly) id version;

- (id) initWithPath: (NSString *)path;


@end