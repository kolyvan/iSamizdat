//
//  TableViewControllerEx.h
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
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


@end
