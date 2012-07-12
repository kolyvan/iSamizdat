//
//  TextViewController2.m
//  iSamizdat
//
//  Created by Kolyvan on 11.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "TextContainerController.h"
#import "KxUtils.h"
#import "KxMacros.h"
#import "TextViewController.h"
#import "TextReadViewController.h"
#import "CommentsViewController.h"
#import "SamLibText.h"

@interface TextContainerController () {
        
    TextViewController * _textViewController;
    TextReadViewController *_textReadViewController;
    CommentsViewController * _commentsViewController;    
    UIViewController *_activeVC;
    SamLibText *_text;
    BOOL _animated;
}
@end

@implementation TextContainerController

@synthesize text = _text;
@synthesize selected = _selected;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
            
    UISegmentedControl *segm = [[UISegmentedControl alloc] initWithFrame: CGRectZero];
    segm.segmentedControlStyle = UISegmentedControlStyleBar;
    [segm insertSegmentWithTitle: locString(@"posts") atIndex: 0 animated: NO];    
    [segm insertSegmentWithTitle: locString(@"text")  atIndex: 0 animated: NO];    
    [segm insertSegmentWithTitle: locString(@"info")  atIndex: 0 animated: NO];                                
    [segm addTarget:self
             action:@selector(segmentedChanged:)
   forControlEvents:UIControlEventValueChanged];    
    [segm sizeToFit];

    self.navigationItem.titleView = segm;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.navigationItem.titleView = nil;
    self.navigationItem.rightBarButtonItem = nil;
    
    _text = nil;
    _activeVC = nil;
    _textViewController = nil;
    _textReadViewController = nil;
    _commentsViewController = nil;   
    
     [self resetObserverNavigationRightButton: NO];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
    
    if (_activeVC != _textViewController)
        _textViewController = nil;
    
    if (_activeVC != _textReadViewController)
        _textReadViewController = nil;
    
    if (_activeVC != _commentsViewController)
        _commentsViewController = nil;    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //UISegmentedControl *segm = (UISegmentedControl *)self.navigationItem.titleView;
    //[segm setEnabled:YES];        
    _animated = NO;
    [self setSelected:_selected animated:NO];    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) setSelected: (NSInteger) selected animated: (BOOL) animated
{
    UIViewController *vc = [self viewControllerByIndex: selected];
    if (vc != _activeVC)
        [self flipVC:vc aminated:animated];
    _selected = selected;
    UISegmentedControl *segm = (UISegmentedControl *)self.navigationItem.titleView;
    segm.selectedSegmentIndex = selected; 
}

#pragma mark - private 

- (UIViewController *) viewControllerByIndex: (NSInteger) selected
{
    UIViewController *vc;
    switch (selected) {
        case TextInfoViewSelected: 
            vc = self.textViewController;
            self.textViewController.text = _text;
            break;
        case TextReadViewSelected: 
            vc = self.textReadViewController;
            self.textReadViewController.text = _text;
            break;
        case TextCommentsViewSelected: 
            vc = self.commentsViewController;
            self.commentsViewController.comments = [_text commentsObject:YES];
            break;            
    }
    return vc;
}

- (void) segmentedChanged: (UISegmentedControl *) sender
{
    NSInteger selected = sender.selectedSegmentIndex;    
    if (_selected == selected || _animated)
        return;    
    UIViewController *toVC = [self viewControllerByIndex: selected];
    [self flipVC:toVC aminated: YES];  
    _selected = selected;
}

- (void) flipVC: (UIViewController *) toVC aminated: (BOOL) animated
{
    [self resetObserverNavigationRightButton: NO];
    
    UIViewController *fromVC = _activeVC;    
    
    [self addChildViewController:toVC];    
    
    CGSize sz = self.view.bounds.size;    
    toVC.view.frame = CGRectMake(0,0, sz.width, sz.height);
    
    [fromVC willMoveToParentViewController:nil];
    
    if (animated) {
                    
        //UISegmentedControl *segm = (UISegmentedControl *)self.navigationItem.titleView;
        //[segm setEnabled:NO];                
        _animated = YES;
        
        [self transitionFromViewController:fromVC
                          toViewController:toVC
                                  duration:0.3
                                   options:UIViewAnimationOptionTransitionFlipFromLeft
                                animations:nil
                                completion:^(BOOL done){
                                    
                                    [toVC didMoveToParentViewController:self];
                                    [fromVC removeFromParentViewController];
                                    //[segm setEnabled:YES];
                                    _animated = NO;                                    
                                }];
    } else {
        
        [self.view addSubview: toVC.view];        
        [toVC didMoveToParentViewController:self];        
        [fromVC removeFromParentViewController];
    }
    
    _activeVC = toVC;    
    self.navigationItem.rightBarButtonItem = _activeVC.navigationItem.rightBarButtonItem;  
    
    [self resetObserverNavigationRightButton: YES];
}

- (void) resetObserverNavigationRightButton: (BOOL) observer
{
    if (observer) {
    
        [_activeVC.navigationItem addObserver:self 
                                   forKeyPath:@"rightBarButtonItem" 
                                      options:NSKeyValueObservingOptionNew 
                                      context:NULL];
    } else {
        
        [_activeVC.navigationItem removeObserver:self 
                                      forKeyPath:@"rightBarButtonItem"];    
    }
}

- (void)observeValueForKeyPath: (NSString*)keyPath
                      ofObject: (id)object
                        change: (NSDictionary*)change
                       context: (void*)context
{
    
    if (_activeVC.navigationItem == object &&
        [keyPath isEqualToString: @"rightBarButtonItem"]) {
        id value = [change objectForKey: NSKeyValueChangeNewKey];
        self.navigationItem.rightBarButtonItem = value == [NSNull null] ? nil : value;
    }    
}

- (TextViewController *) textViewController
{
    if (!_textViewController) {
        
        _textViewController = [[TextViewController alloc] init];        
        _textViewController.view.tag = TextInfoViewSelected;
    }    
    return _textViewController;
}

- (TextReadViewController *) textReadViewController
{
    if (!_textReadViewController) {
        
        _textReadViewController = [[TextReadViewController alloc] init];        
        _textReadViewController.view.tag = TextReadViewSelected;
    }    
    return _textReadViewController;
}

- (CommentsViewController *) commentsViewController
{
    if (!_commentsViewController) {
        
        _commentsViewController = [[CommentsViewController alloc] init];        
        _commentsViewController.view.tag = TextCommentsViewSelected;        
    }    
    return _commentsViewController;
}

@end
	