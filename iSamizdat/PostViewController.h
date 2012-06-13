//
//  ReplyViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import <UIKit/UIKit.h>
#import "KxArc.h"
#import "UserViewController.h"

@class SamLibComment;
@class PostViewController;

@protocol PostViewDelagate <NSObject>
- (void) sendPost: (NSString *) message
          comment: (NSString *) msgid 
           isEdit: (BOOL) isEdit;  
@end

@interface PostViewController : UIViewController<UITextViewDelegate, UserViewDelegate>

@property (nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) SamLibComment *comment;
@property (nonatomic) BOOL isEdit;
@property (nonatomic, KX_PROP_WEAK) id<PostViewDelagate> delegate;

@end
