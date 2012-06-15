//
//  TextGroupViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 15.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import <UIKit/UIKit.h>

@interface TextGroupViewController : UITableViewController
@property (readwrite, nonatomic, strong) NSArray * texts;
@end
