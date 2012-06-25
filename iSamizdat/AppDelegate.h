//
//  AppDelegate.h
//  iSamizdat
//
//  Created by Kolyvan on 28.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (AppDelegate *) shared;

- (void) errorNoticeInView:(UIView *) view
                     title:(NSString *) title
                   message:(NSString *) message;

- (void) successNoticeInView:(UIView *) view
                       title:(NSString *) title;

- (void) closeNotice;

- (void) checkLogin;

@end
