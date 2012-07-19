//
//  VotedViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 17.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "VotedViewController.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"


UIImage * mkVoteImage(NSInteger number, BOOL selected)
{
    if (selected)
        return [UIImage imageNamed:KxUtils.format(@"mark_%02d_28", number)];
    else
        return [UIImage imageNamed:KxUtils.format(@"mark_%02d_32", number)];
}

@interface VotedViewController () {
    BOOL _sortByVote;
}
@end

@implementation VotedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.title = locString(@"Voted");
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:locString(@"Voted")
                                                        image:[UIImage imageNamed:@"voted"] 
                                                          tag:0];
 
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *backBtn =  [[UIBarButtonItem alloc] initWithTitle:locString(@"Voted")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
    self.navigationItem.backBarButtonItem = backBtn;

        
    
    UIBarButtonItem *sortBtn =  [[UIBarButtonItem alloc] initWithTitle:locString(@"by vote")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(toggleSort:)];
    
    self.navigationItem.rightBarButtonItem = sortBtn;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.backBarButtonItem = nil;    
    _sortByVote = NO;
}

- (void) toggleSort: (UIBarButtonItem *) button
{
    _sortByVote = !_sortByVote;
    button.title = _sortByVote ? locString(@"by author") : locString(@"by vote");
    [self refreshView];
}

- (void) refreshTitle: (NSInteger) count
{
    self.navigationItem.title = count ? KxUtils.format(@"%@ (%d)", locString(@"Voted"), count) : locString(@"Voted");
}

- (NSArray *) prepareData
{
    NSArray *authors = [SamLibModel shared].authors;
    
    NSMutableArray *ma = [NSMutableArray array];
    
    for (SamLibAuthor *author in authors) {
        if (!author.ignored) {
            for (SamLibText *text in author.texts) {            
                if (text.myVote != 0)
                    [ma push:text];  
            }
        }
    }
    
    if (_sortByVote) {
    
        return [ma sortWith:^(SamLibText *l, SamLibText *r) {
            // reversi order
            if (l.myVote > r.myVote) return NSOrderedAscending;
            if (l.myVote < r.myVote) return NSOrderedDescending;
            return NSOrderedSame;            
        }];
    }
    
    [self refreshTitle: ma.count];
    
    return ma;
}

- (BOOL) canRemoveText: (SamLibText *) text
{
    return YES;
}

- (void) handleRemoveText: (SamLibText *) text
{
    KX_WEAK VotedViewController *this = self;
    
    [text vote:SamLibTextVote0 block:^(SamLibText *text, SamLibStatus status, NSString *error){

        VotedViewController *p = this;
        if (p) {
            if (status == SamLibStatusSuccess)
                [p refreshTitle:p.texts.count];
            else
                [self refreshView];            
        }        
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell; 
    cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleSubtitle];    
                
    SamLibText *text = [self.texts objectAtIndex:indexPath.row];     
    cell.textLabel.text = text.title;
    cell.detailTextLabel.text = text.author.name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = mkVoteImage(text.myVote, YES);
    return cell;
}

@end
