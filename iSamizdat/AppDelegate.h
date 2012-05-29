//
//  AppDelegate.h
//  iSamizdat
//
//  Created by Kolyvan on 28.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
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

@end
