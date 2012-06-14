//
//  TableViewControllerEx.h
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import <UIKit/UIKit.h>
#import "SSPullToRefresh.h"
#import "SamLib.h"

@interface TableViewControllerEx : UITableViewController<SSPullToRefreshViewDelegate>

@property (nonatomic, strong) SSPullToRefreshView *pullToRefreshView;
@property (nonatomic, strong) UIBarButtonItem *stopButton;


// abstract
- (NSDate *) lastUpdateDate;
- (void) refresh: (void(^)(SamLibStatus status, NSString *error)) block;
- (void) prepareData;

// actions
- (IBAction) goStop;

// helpers
- (id) mkCell: (NSString *) cellIdentifier
    withStyle: (UITableViewCellStyle) style;

- (void) showNoticeAboutReloadResult: (NSString *) error;
- (void) handleStatus: (SamLibStatus) status 
            withError: (NSString *)error;

@end
