//
//  SamLibText.h
//  samlib
//
//  Created by Kolyvan on 09.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import <Foundation/Foundation.h>
#import "KxArc.h"
#import "SamLib.h"
#import "SamLibAgent.h"

typedef void (^UpdateTextBlock)(SamLibText *text, SamLibStatus status, NSString *error);
typedef NSString *(^TextFormatter)(SamLibText *text, NSString *s);
typedef void (^FetchVotesBlock)(SamLibText *text, NSArray *votes, SamLibStatus status, NSString *error);

typedef enum {
    
    SamLibTextChangedNone        = 0,        
    SamLibTextChangedSize        = 1 << 0,    
    SamLibTextChangedNote        = 1 << 1,    
    SamLibTextChangedComments    = 1 << 2,
    SamLibTextChangedRating      = 1 << 3,        
    SamLibTextChangedCopyright   = 1 << 4,        
    SamLibTextChangedTitle       = 1 << 5,       
    SamLibTextChangedGenre       = 1 << 6,          
    SamLibTextChangedGroup       = 1 << 7,
    SamLibTextChangedType        = 1 << 8,    
    SamLibTextChangedRemoved     = 1 << 9,  
    SamLibTextChangedNew        = 1 << 10,      
    
} SamLibTextChanged;

typedef enum {

    SamLibTextVote0, // none, не читал        
    
    SamLibTextVote1, // must not read, не читать    
    SamLibTextVote2, // very bad, очень плохо   
    SamLibTextVote3, // bad, плохо    
    SamLibTextVote4, // mediocre, посредственно
    SamLibTextVote5, // nothing, терпимо   

    SamLibTextVote6, // normally, нормально
    SamLibTextVote7, // good, хорошо   
    SamLibTextVote8, // very good, очень хорошо
    SamLibTextVote9, // great, замечательно       
    SamLibTextVote10,// masterwork, шедевр
    
} SamLibTextVote;


// 
@class SamLibComments;

@interface SamLibText : SamLibBase {
@protected    

    NSString * _copyright;
    NSString * _title;
    NSString * _size;
    NSString * _comments;        
    NSString * _note;
    NSString * _genre;
    NSString * _group;
    NSString * _type;
    NSString * _rating;        
    NSString * _flagNew;
    NSString * _lastModified;
    NSString * _diffResult;
    NSDate * _filetime;
    NSString *_dateModified;
    BOOL _favorited;    
    SamLibTextVote _myVote;        
    unsigned long long _position;
    unsigned long long _cachedFileSize;

    SamLibTextChanged _changedFlag;        
    NSInteger _deltaSize;
    NSInteger _deltaComments;    
    float _deltaRating;
    
    KX_WEAK SamLibAuthor * _author;
    SamLibComments * _commentsObject;
    
    NSInteger _version;
}

@property (readonly, nonatomic, KX_PROP_STRONG) NSString * copyright;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * title;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * size;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * comments;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * note;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * genre;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * group;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * type;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * rating;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * flagNew;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * dateModified;

@property (readonly, nonatomic) NSInteger sizeInt;
@property (readonly, nonatomic) NSInteger commentsInt;
@property (readonly, nonatomic) float ratingFloat;
@property (readonly, nonatomic) NSInteger deltaSize;
@property (readonly, nonatomic) NSInteger deltaComments;
@property (readonly, nonatomic) float deltaRating;

@property (readonly, nonatomic) SamLibTextChanged changedFlag;
@property (readonly) BOOL changedSize;
@property (readonly) BOOL changedNote;
@property (readonly) BOOL changedComments;
@property (readonly) BOOL changedRating;
@property (readonly) BOOL changedCopyright;
@property (readonly) BOOL changedTitle;
@property (readonly) BOOL changedGenre;
@property (readonly) BOOL changedGroup;
@property (readonly) BOOL changedType;
@property (readonly) BOOL isRemoved;
@property (readonly) BOOL isNew;

@property (readonly) NSString * key;

@property (readonly, KX_PROP_WEAK) SamLibAuthor * author;

@property (readonly, nonatomic, KX_PROP_STRONG) NSDate * filetime;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * lastModified;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * diffResult;

@property (readonly, nonatomic) NSString * htmlFile;
@property (readonly, nonatomic) NSString * diffFile;
@property (readonly, nonatomic) NSString * commentsFile;

@property (readonly, nonatomic) BOOL canUpdate;
@property (readonly, nonatomic) BOOL canMakeDiff;

@property (readonly, nonatomic) NSString * groupEx;

@property (readwrite, nonatomic) BOOL favorited;
@property (readwrite, nonatomic) CGFloat scrollOffset;
@property (readonly, nonatomic) SamLibTextVote myVote;

+ (id) fromDictionary: (NSDictionary *) dict 
           withAuthor: (SamLibAuthor *) author;

- (id) initFromDictionary: (NSDictionary *) dict
                 withPath: (NSString *)path
                andAuthor: (SamLibAuthor *) author;

- (void) updateFromDictionary: (NSDictionary *) dict;

- (NSDictionary *) toDictionary;

- (void) flagAsRemoved;
- (void) flagAsNew;
- (void) flagAsChangedNone;

- (void) update: (UpdateTextBlock) block 
       progress: (AsyncProgressBlock) progress
      formatter: (TextFormatter) formatter;

- (void) makeDiff: (TextFormatter) formatter;

- (SamLibComments *) commentsObject: (BOOL) forceLoad;
- (void) freeCommentsObject;

- (NSString *) sizeWithDelta: (NSString *)sep;
- (NSString *) commentsWithDelta: (NSString *)sep;;
- (NSString *) ratingWithDelta: (NSString *)sep;


- (void) vote: (SamLibTextVote) value 
        block: (UpdateTextBlock) block;

//- (void) fetchVotes: (FetchVotesBlock) block;


- (void) removeTextFiles: (BOOL) texts 
             andComments: (BOOL) comments;

- (NSString *) makeKey: (NSString *) sep;

@end
