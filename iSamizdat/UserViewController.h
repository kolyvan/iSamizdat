//
//  UserViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 04.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KxArc.h"

@protocol UserViewDelegate <NSObject>
- (BOOL) userInfoChanged;
@end

@interface UserViewController : UITableViewController
@property (nonatomic, KX_PROP_WEAK) id<UserViewDelegate> delegate;
@end
