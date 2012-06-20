//
//  SamLibAuthor.h
//  samlib
//
//  Created by Kolyvan on 08.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import <Foundation/Foundation.h>
#import "SamLib.h"
#import "KxArc.h"

typedef void (^UpdateAuthorBlock)(SamLibAuthor *author, SamLibStatus status, NSString *error);

@interface SamLibAuthor : SamLibBase {
@protected
    NSString * _name;    
    NSString * _title;    
    NSString * _updated;
    NSString * _size; 
    NSString * _rating;
    NSString * _visitors;
    NSString * _www;
    NSString * _email;   
    NSString * _lastModified;
    NSString * _digest;
    NSString * _about;    
    NSArray * _texts;
    BOOL _changed;
    BOOL _ignored;
    
    NSString *_hash;
    NSInteger _version;
}

@property (readonly, nonatomic, KX_PROP_STRONG) NSString * name;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * title;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * updated;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * size;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * rating;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * visitors;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * www;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * email;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * lastModified;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * digest;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * about;
@property (readonly, nonatomic, KX_PROP_STRONG) NSArray * texts;
@property (readwrite, nonatomic) BOOL ignored;

@property (readonly, nonatomic) float ratingFloat;
@property (readonly, nonatomic) BOOL isDirty;


+ (id) fromDictionary: (NSDictionary *)dict withPath: (NSString *) path;

- (NSDictionary *) toDictionary;

- (SamLibText *) findText: (NSString *) byPath;

- (void) update: (UpdateAuthorBlock) block;

+ (id) fromFile: (NSString *) filepath;

- (void) save: (NSString *)folder;

- (void) gcRemovedText;

@end
