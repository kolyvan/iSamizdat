//
//  TextReadViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import <UIKit/UIKit.h>
#import "SSPullToRefreshView+Kolyvan.h"

@class SamLibText;

@interface TextReadViewController : UIViewController<UIWebViewDelegate, SSPullToRefreshViewDelegate>
@property (nonatomic, strong) SamLibText *text;
@end


extern NSString * mkHTMLPage(SamLibText * text, NSString * html);