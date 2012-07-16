//
//  ImageViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 16.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UrlImageViewController : UIViewController
@property (readwrite, nonatomic, strong) NSURL *url;
@property (readwrite, nonatomic) BOOL fullscreen;
@end
