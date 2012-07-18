//
//  ImageViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 16.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "UrlImageViewController.h"
#import "KxMacros.h"
#import "UIImageView+AFNetworking.h"
#import "UITabBarController+Kolyvan.h"

@interface UrlImageViewController () {
    UIImageView *_imageView;
    UITapGestureRecognizer *_tapGestureRecognizer;  
    UISwipeGestureRecognizer *_swipeGestureRecognizer;
    UIPinchGestureRecognizer *_pinchGestureRecognizer;
}
@end

@implementation UrlImageViewController
@synthesize url = _url;
@synthesize fullscreen = _fullscreen;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        //self.title = locString(@"Image View");
    }
    return self;
}

- (void) loadView
{
    _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];    
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.view = _imageView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self 
                                                                    action:@selector(handleTap:)];   
    
    _swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                  action:@selector(handleSwipe:)]; 
    _swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    
    _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(handlePinch:)]; 
    
    _imageView.userInteractionEnabled = YES;
    
    [_imageView addGestureRecognizer:_tapGestureRecognizer];
    [_imageView addGestureRecognizer:_swipeGestureRecognizer];
    [_imageView addGestureRecognizer:_pinchGestureRecognizer];    

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];  
    _imageView.transform = CGAffineTransformIdentity;
    [_imageView setImageWithURL:_url];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    _tapGestureRecognizer = nil;
    _swipeGestureRecognizer = nil;
    _pinchGestureRecognizer = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) handleTap: (UITapGestureRecognizer *) sender
{   
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self fullscreenMode:!_fullscreen] ;
    }
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)sender 
{   
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        [self.navigationController popViewControllerAnimated:YES];        
    } 
}

- (void)handlePinch:(UIPinchGestureRecognizer *)sender 
{
    if (sender.state == UIGestureRecognizerStateChanged) {
        
        CGFloat scale = sender.scale;        
        //[UIView beginAnimations:nil context:NULL];        
        _imageView.transform = CGAffineTransformMakeScale(scale, scale);
        //[UIView commitAnimations];
    } 
}

- (void) fullscreenMode: (BOOL) on
{   
    _fullscreen = on;    
    UIApplication *app = [UIApplication sharedApplication];    
    [app setStatusBarHidden:on withAnimation:UIStatusBarAnimationSlide];        
    [self.navigationController setNavigationBarHidden:on animated:YES];
    [self.tabBarController setTabBarHidden:on animated:YES];       
    _imageView.transform = CGAffineTransformIdentity;
}

@end

