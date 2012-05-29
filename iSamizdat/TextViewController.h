//
//  TextViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 29.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <UIKit/UIKit.h>

@class SamLibText;

@interface TextViewController : UITableViewController

@property (nonatomic, strong) SamLibText *text;

@end
