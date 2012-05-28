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
    
    NSString *_hash;
    NSInteger _version;
}

@property (readonly, nonatomic) NSString * name;
@property (readonly, nonatomic) NSString * title;
@property (readonly, nonatomic) NSString * updated;
@property (readonly, nonatomic) NSString * size;
@property (readonly, nonatomic) NSString * rating;
@property (readonly, nonatomic) NSString * visitors;
@property (readonly, nonatomic) NSString * www;
@property (readonly, nonatomic) NSString * email;
@property (readonly, nonatomic) NSString * lastModified;
@property (readonly, nonatomic) NSString * digest;
@property (readonly, nonatomic) NSString * about;
@property (readonly, nonatomic) NSArray * texts;
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

+ (void) fuzzySearchAuthorByName: (NSString *) name 
                    minDistance1: (float) minDistance1  // 0.2
                    minDistance2: (float) minDistance2  // 0.4
                           block: (void(^)(NSArray *result)) block;

@end
