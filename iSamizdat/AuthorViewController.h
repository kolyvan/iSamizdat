//
//  AuthorViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 29.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSPullToRefresh.h"

@class SamLibAuthor;

@interface AuthorViewController : UITableViewController<SSPullToRefreshViewDelegate>
@property (strong, nonatomic) SamLibAuthor *author;
@end
