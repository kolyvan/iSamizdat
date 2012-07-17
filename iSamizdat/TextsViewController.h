//
//  TextsViewController.h
//  iSamizdat
//
//  Created by Kolyvan on 16.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextContainerController.h"

@class SamLibText;

@interface TextsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (readonly, nonatomic, strong) NSArray *texts;
@property (readonly) UITableView *tableView;
@property (nonatomic, strong) TextContainerController *textContainerController;

// override
- (NSArray *) prepareData;
- (NSInteger) textContainerSelected;
- (BOOL) canRemoveText: (SamLibText *) text;
- (void) handleRemoveText: (SamLibText *) text;

// helpers
- (void) refreshView;
- (id) mkCell: (NSString *) cellIdentifier
    withStyle: (UITableViewCellStyle) style;

@end
