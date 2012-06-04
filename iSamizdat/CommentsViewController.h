//
//  CommentsViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TableViewControllerEx.h"
#import "PostViewController.h"
#import "CommentCell.h"

@class SamLibComments;
@class SamLibComment;

@interface CommentsViewController : TableViewControllerEx<CommentCellDelegate, PostViewDelagate, UIActionSheetDelegate>
@property (nonatomic, strong) SamLibComments *comments;

@end
