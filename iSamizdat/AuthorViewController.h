//
//  AuthorViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 29.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import <UIKit/UIKit.h>
#import "SSPullToRefresh.h"

@class SamLibAuthor;

@interface AuthorViewController : UITableViewController<SSPullToRefreshViewDelegate>
@property (strong, nonatomic) SamLibAuthor *author;
@end
