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

- (IBAction) goStop
{
    SamLibAgent.cancelAll();
    [self.pullToRefreshView finishLoading];
    self.navigationItem.rightBarButtonItem = self.savedRightButton;    
}

- (void) showNoticeAboutReloadResult: (NSString *) error
{
    if (error) {
        
        [[AppDelegate shared] errorNoticeInView:self.view 
                                          title:locString(@"Reload failure") 
                                        message:error];        
    } else {
        
        [[AppDelegate shared] successNoticeInView:self.view 
                                            title:locString(@"Reload success")];
    }
}

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view 
{   
    self.savedRightButton = self.navigationItem.rightBarButtonItem;
    self.navigationItem.rightBarButtonItem = self.stopButton;
    
    NSDate * lastUpdateDate = [self lastUpdateDate];
    if (lastUpdateDate)
        [self.pullToRefreshView.contentView setLastUpdatedAt:lastUpdateDate
                                       withPullToRefreshView:self.pullToRefreshView]; 
    
    [self.pullToRefreshView startLoading];  
    
    [self refresh: ^(SamLibStatus status, NSString *error) {
        
        [self.pullToRefreshView finishLoading];
        self.navigationItem.rightBarButtonItem = self.savedRightButton;
        
        if (status == SamLibStatusFailure) {
            
            [self performSelector:@selector(showNoticeAboutReloadResult:) 
                       withObject:error ? error : @""
                       afterDelay:0.3];
            
        } else if (status == SamLibStatusSuccess) {            
                        
            [self performSelector:@selector(showNoticeAboutReloadResult:) 
                       withObject:nil
                       afterDelay:0.3];
        }
    
        if (status != SamLibStatusNotModifed) {
            [self prepareData];
            [self.tableView reloadData];            
        }
        
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

@end
