//
//  AuthorInfoViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 15.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <UIKit/UIKit.h>

@class SamLibAuthor;

@interface AuthorInfoViewController : UITableViewController<UIActionSheetDelegate>
@property (readwrite, nonatomic, strong) SamLibAuthor *author; 
@end
