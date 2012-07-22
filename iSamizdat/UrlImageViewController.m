//
//  ImageViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 16.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "UrlImageViewController.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "UIImageView+AFNetworking.h"
#import "UITabBarController+Kolyvan.h"

#define VELOCITY_FACTOR 0.014

@interface UrlImageViewController () <UIGestureRecognizerDelegate> {
    UIImageView *_imageView;
    UITapGestureRecognizer *_tapGestureRecognizer;  
    UISwipeGestureRecognizer *_swipeGestureRecognizer;
    UIPinchGestureRecognizer *_pinchGestureRecognizer;
    UIPanGestureRecognizer *_panGestureRecognizer;
    UIActivityIndicatorView *_activityIndicatorView;    
    CGFloat scaleFactor;
    CGPoint translateFactor;
}
@end

@implementation UrlImageViewController
@synthesize url = _url;
@synthesize fullscreen = _fullscreen;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];    
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _imageView.contentMode = UIViewContentModeScaleAspectFit;        
    [self.view addSubview:_imageView];   
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];    
    _activityIndicatorView.hidesWhenStopped = YES;
    [self.view addSubview:_activityIndicatorView];
    _activityIndicatorView.center = CGPointMake(self.view.center.x, 100); 
    
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self 
                                                                    action:@selector(handleTap:)];   
    
    _tapGestureRecognizer.delegate = self;
    
    
    _swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                  action:@selector(handleSwipe:)]; 
    _swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    _swipeGestureRecognizer.delegate = self;
     
    _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(handlePinch:)]; 
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGestureRecognizer.delegate = self;
    
    _imageView.userInteractionEnabled = YES;
    
    [_imageView addGestureRecognizer:_tapGestureRecognizer];
    [_imageView addGestureRecognizer:_swipeGestureRecognizer];
    [_imageView addGestureRecognizer:_pinchGestureRecognizer]; 
    [_imageView addGestureRecognizer:_panGestureRecognizer]; 
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];  
    
    [self resetDownload: nil];    
    [self setImageWithURL: _url];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [_imageView removeGestureRecognizer:_tapGestureRecognizer];
    [_imageView removeGestureRecognizer:_swipeGestureRecognizer];
    [_imageView removeGestureRecognizer:_pinchGestureRecognizer];
    [_imageView removeGestureRecognizer:_panGestureRecognizer];    
    
    _tapGestureRecognizer.delegate = nil;
    _swipeGestureRecognizer.delegate = nil;
    _panGestureRecognizer.delegate = nil;
    
    _tapGestureRecognizer = nil;
    _swipeGestureRecognizer = nil;
    _pinchGestureRecognizer = nil;
    _panGestureRecognizer = nil;
    
    [_imageView removeFromSuperview];
    [_activityIndicatorView removeFromSuperview];
    
    _imageView = nil;
    _activityIndicatorView = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer 
       shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer != _tapGestureRecognizer) 
        return YES;
    
    CGPoint pt = [touch locationInView:self.view];
    CGRect bounds = self.view.bounds;
    CGFloat w = bounds.size.width;
    CGFloat l = bounds.origin.x + w * .33;
    CGFloat r = bounds.origin.x + w * .66;    
    
    if ((pt.x > l) && (pt.x < r)) {    
        return YES;        
    }    
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == _swipeGestureRecognizer) 
        return scaleFactor == 1.0;
    
    if (gestureRecognizer == _panGestureRecognizer) 
        return scaleFactor != 1.0;
    
    return YES;
}

- (void) handleTap: (UITapGestureRecognizer *) sender
{   
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        NSLog(@"handleTap number %d", sender.numberOfTouches);
        
        [self fullscreenMode:!_fullscreen];        
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
        
        scaleFactor += sender.velocity * VELOCITY_FACTOR;
        [self applyTransform];
    } 
}

- (void) handlePan: (UIPanGestureRecognizer *) sender
{   
    if (sender.state == UIGestureRecognizerStateChanged) {
        
        CGPoint pt = [sender velocityInView:self.view];                
        translateFactor.x += pt.x * VELOCITY_FACTOR;
        translateFactor.y += pt.y * VELOCITY_FACTOR;
        [self applyTransform];
    } 
}

- (void) fullscreenMode: (BOOL) on
{   
    _fullscreen = on;    
    UIApplication *app = [UIApplication sharedApplication];    
    [app setStatusBarHidden:on withAnimation:UIStatusBarAnimationSlide];        
    [self.navigationController setNavigationBarHidden:on animated:YES];
    [self.tabBarController setTabBarHidden:on animated:YES]; 
    
    scaleFactor = 1;
    translateFactor = CGPointZero;
    _imageView.transform = CGAffineTransformIdentity;
}

- (void) applyTransform
{
    _imageView.transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(translateFactor.x, translateFactor.y), 
                                                   CGAffineTransformMakeScale(scaleFactor, scaleFactor));

}

- (void) resetDownload: (NSError *) error
{
    scaleFactor = 1;
    translateFactor = CGPointZero;    
    _imageView.transform = CGAffineTransformIdentity;
    
    [_activityIndicatorView stopAnimating];  
    self.title = @"";
}

- (void)setImageWithURL:(NSURL *)url 
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url 
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy 
                                                       timeoutInterval:30.0];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];
    
    [_activityIndicatorView startAnimating];
    
    KX_WEAK UrlImageViewController *this = self;
    self.title = locString(@"Loading...");

    [_imageView setImageWithURLRequest:request 
                      placeholderImage:nil 
                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                   
                                   UrlImageViewController *p = this;
                                   if (p) [p resetDownload: nil];
                                                                  
                               }
                               failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {

                                   UrlImageViewController *p = this;
                                   if (p) [p resetDownload: error];
                                   
                               }];
}

@end

