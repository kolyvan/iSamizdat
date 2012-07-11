//
//  TextViewController2.h
//  iSamizdat
//
//  Created by Kolyvan on 11.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import <UIKit/UIKit.h>

@class SamLibText;

#define TextInfoViewSelected 0
#define TextReadViewSelected 1
#define TextCommentsViewSelected 2

@interface TextContainerController : UIViewController

@property (readwrite, nonatomic, strong) SamLibText *text;
@property (readwrite, nonatomic) NSInteger selected;

- (void) setSelected: (NSInteger) selected animated: (BOOL) animated;

@end
