//
//  TextReadViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <UIKit/UIKit.h>

@class SamLibText;

@interface TextReadViewController : UIViewController<UIWebViewDelegate>
@property (nonatomic, strong) SamLibText *text;
@end
