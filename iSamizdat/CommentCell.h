//
//  CommentCell.h
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KxArc.h"
#import "FastCell.h"

@class SamLibComment;

@protocol CommentCellDelegate <NSObject>

- (void) replyPost: (SamLibComment *) comment;
- (void) deletePost: (SamLibComment *) comment;
- (void) editPost: (SamLibComment *) comment;

@end

@interface CommentCell : FastCell

@property (nonatomic, KX_PROP_WEAK) id<CommentCellDelegate> delegate;
@property (nonatomic, strong) SamLibComment *comment;
@property (readonly, nonatomic) BOOL wantTouches;

+ (CGFloat) heightForComment:(SamLibComment *)comment 
                   withWidth:(CGFloat) width;

- (id) initWithStyle:(UITableViewCellStyle)style 
     reuseIdentifier:(NSString *)reuseIdentifier;





@end
