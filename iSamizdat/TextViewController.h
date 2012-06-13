//
//  TextViewController.h
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
#import "TableViewControllerEx.h"
#import "VoteViewController.h"

@class SamLibText;

@interface TextViewController : TableViewControllerEx<VoteViewDelagate>

@property (nonatomic, strong) SamLibText *text;

- (void) sendVote: (NSInteger) vote;  

@end
