//
//  CommentsViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TableViewControllerEx.h"

@class SamLibComments;

@interface CommentsViewController : TableViewControllerEx
@property (nonatomic, strong) SamLibComments *comments;
@end
