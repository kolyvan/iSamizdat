//
//  TableViewControllerEx.m
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "TableViewControllerEx.h"
#import "AppDelegate.h"
#import "SamLibAgent.h"
#import "KxMacros.h"
#import "NSString+Kolyvan.h"
#import "SSPullToRefreshView+Kolyvan.h"

////

@interface TableViewControllerEx()

@property (nonatomic, strong) UIBarButtonItem *savedRightButton;

@end

@implementation TableViewControllerEx

@synthesize pullToRefreshView;
@synthesize stopButton;
@synthesize savedRightButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop 
                                                                    target:self 
                                                                    action:@selector(goStop)];
    
    self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView 
                                                                    delegate:self];
    
    self.pullToRefreshView.contentView = [[LocalizedPullToRefreshContentView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidUnload
{
    [super viewDidUnload];    
    self.navigationItem.backBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    self.pullToRefreshView = nil;
    self.stopButton = nil;
    self.savedRightButton = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[AppDelegate shared] closeNotice]; 
    [self refreshLastUpdated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) prepareData
{
}

- (void) refresh: (void(^)(SamLibStatus status, NSString *error)) block
{
    block(SamLibStatusNotModifed, nil);
}

- (NSDate *) lastUpdateDate
{
    return nil;
}

- (void) refreshLastUpdated
{
    [self.pullToRefreshView.contentView setLastUpdatedAt:[self lastUpdateDate]
                                   withPullToRefreshView:self.pullToRefreshView]; 
}

- (IBAction) goStop
{
    SamLibAgent.cancelAll();
    [self.pullToRefreshView finishLoading];
    self.navigationItem.rightBarButtonItem = self.savedRightButton; 
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void) showSuccessNoticeAboutReloadResult: (NSString *) message
{        
    [[AppDelegate shared] successNoticeInView:self.view 
                                        title:message.nonEmpty ? message : locString(@"Reload success")];    
}

- (void) showFailureNoticeAboutReloadResult: (NSString *) message
{   
    [[AppDelegate shared] errorNoticeInView:self.view 
                                      title:locString(@"Reload failure") 
                                    message:message.nonEmpty ? message : @""];        
}

- (void) handleStatus: (SamLibStatus) status 
          withMessage: (NSString *)message
{
    if (status == SamLibStatusFailure) {
        
        [self performSelector:@selector(showFailureNoticeAboutReloadResult:) 
                   withObject:message
                   afterDelay:0.3];
        
    } else if (status == SamLibStatusSuccess) {            
        
        [self refreshLastUpdated];
        
        [self performSelector:@selector(showSuccessNoticeAboutReloadResult:) 
                   withObject:message
                   afterDelay:0.3];
        
    }  else if (status == SamLibStatusNotModifed) {            
        
        [self performSelector:@selector(showSuccessNoticeAboutReloadResult:) 
                   withObject:locString(@"Not modified")
                   afterDelay:0.3];
    }

    
    if (status != SamLibStatusNotModifed) {
        [self prepareData];
        [self.tableView reloadData];            
    }
}

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view 
{   
    self.savedRightButton = self.navigationItem.rightBarButtonItem;
    self.navigationItem.rightBarButtonItem = self.stopButton;
    
    [self.pullToRefreshView startLoading];  
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self refresh: ^(SamLibStatus status, NSString *message) {
        
        [self.pullToRefreshView finishLoading];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        self.navigationItem.rightBarButtonItem = self.savedRightButton;
        [self handleStatus: status withMessage:message];        
    }];
}

- (id) mkCell: (NSString *) cellIdentifier
    withStyle: (UITableViewCellStyle) style
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier];                
    }
    return cell;
}

- (void) forceRefresh
{
    [self.pullToRefreshView startLoadingAndForceExpand];    
}

@end
