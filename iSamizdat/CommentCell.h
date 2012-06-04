//
//  CommentCell.h
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FastCell.h"

@class SamLibComment;
@class CommentsViewController;

@interface CommentCell : FastCell

@property (nonatomic, strong) SamLibComment *comment;
@property (readonly, nonatomic) BOOL wantTouches;

+ (CGFloat) heightForComment:(SamLibComment *)comment 
                   withWidth:(CGFloat) width;

- (id) initWithStyle:(UITableViewCellStyle)style 
     reuseIdentifier:(NSString *)reuseIdentifier 
          controller:(CommentsViewController *)controller; 

@end
