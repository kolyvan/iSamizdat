//
//  AddAuthorViewController.h
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
#import "KxArc.h"

@class SamLibAuthor;

@protocol NewAuthorViewDelegate <NSObject>
- (void) addNewAuthor: (SamLibAuthor *) author;
@end

@interface NewAuthorViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, KX_PROP_WEAK) id<NewAuthorViewDelegate> delegate;
@end
