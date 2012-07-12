//
//  SamLibComments.h
//  samlib
//
//  Created by Kolyvan on 10.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import <Foundation/Foundation.h>
#import "SamLib.h"

@class SamLibComments;

typedef void (^UpdateCommentsBlock)(SamLibComments *comments, 
                                    SamLibStatus status,                                    
                                    NSString *error);

@interface SamLibComment : NSObject

@property (readonly, nonatomic) NSInteger number;
@property (readonly, nonatomic) NSString * deleteMsg;
@property (readonly, nonatomic) NSString * name;
@property (readonly, nonatomic) NSString * link;
@property (readonly, nonatomic) NSString * color;
@property (readonly, nonatomic) NSString * email;
@property (readonly, nonatomic) NSString * msgid;
@property (readonly, nonatomic) NSString * replyto;
@property (readonly, nonatomic) NSString * message;
@property (readonly, nonatomic) NSDate * timestamp;
@property (readonly, nonatomic) BOOL isSamizdat;
@property (readonly, nonatomic) BOOL canEdit;
@property (readonly, nonatomic) BOOL canDelete;
@property (readonly, nonatomic) NSInteger msgidNumber;
@property (readwrite, nonatomic) BOOL isNew;
@property (readonly, nonatomic) BOOL isHidden;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSString *filter;

+ (id) fromDictionary: (NSDictionary *) dict;

- (NSDictionary *) toDictionary;

- (NSComparisonResult) compare: (SamLibComment *) other;

@end

////

@interface SamLibComments : SamLibBase {

    KX_WEAK SamLibText * _text;    
    NSArray * _all;
    NSString *_lastModified;
    BOOL _isDirty;
    NSInteger _numberOfNew;
    NSInteger _version;
}

@property (readonly, nonatomic, KX_PROP_WEAK) SamLibText * text;
@property (readonly, nonatomic, KX_PROP_STRONG) NSArray * all;
@property (readonly, nonatomic, KX_PROP_STRONG) NSString * lastModified;
@property (readonly, nonatomic) BOOL changed;
@property (readonly, nonatomic) BOOL isDirty;
@property (readonly, nonatomic) NSInteger numberOfNew; 

+ (id) fromFile: (NSString *) filepath withText: (SamLibText *) text;
+ (id) fromDictionary: (NSDictionary *)dict withText: (SamLibText *) text;

- (id) initFromDictionary: (NSDictionary *)dict withText: (SamLibText *) text;

- (NSDictionary *) toDictionary;

- (void) update: (BOOL) force 
          block: (UpdateCommentsBlock) block;

- (void) deleteComment: (NSString *) msgid
                 block: (UpdateCommentsBlock) block;


- (void) save: (NSString *)folder;

- (void) post: (NSString *) message 
        block: (UpdateCommentsBlock) block;

- (void) post: (NSString *) message 
        msgid: (NSString *) msgid        
      isReply: (BOOL) isReply
        block: (UpdateCommentsBlock) block;

- (SamLibComment *) findCommentByMsgid: (NSString *) msgid;

- (void) setHiddenFlag: (BOOL) isHidden 
            forComment: (SamLibComment *) comment;

@end
