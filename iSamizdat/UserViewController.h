//
//  UserViewController.h
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

@protocol UserViewDelegate <NSObject>
- (BOOL) userInfoChanged;
@end

@interface UserViewController : UITableViewController
@property (nonatomic, KX_PROP_WEAK) id<UserViewDelegate> delegate;
@end
