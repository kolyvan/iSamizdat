//
//  VoteViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 13.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "VoteViewController.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "SamLibText+IOS.h"
#import "UIFont+Kolyvan.h"
#import "VotedViewController.h"
#import "UIColor+Kolyvan.h"

@interface VoteViewController () {
    //BOOL _needReload;
}
@end

@implementation VoteViewController

@synthesize delegate;
@synthesize myVote = _myVote;

- (void) setMyVote:(NSInteger)myVote
{
    if (myVote != _myVote) {
        [self refreshTable:myVote];
        _myVote = myVote;
        //_needReload = YES;
    }
}

- (id) init
{
    self =  [self initWithNibName:@"VoteViewController" bundle:nil];
    if (self) {
        self.title = locString(@"My vote");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave 
                                                                   target:self 
                                                                   action:@selector(goSend)];

    self.navigationItem.rightBarButtonItem = sendButton;  
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem.enabled = NO;  
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.navigationItem.rightBarButtonItem = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) goSend
{
    [self.navigationController popViewControllerAnimated:YES];    
    if (self.delegate)
        [self.delegate sendVote:_myVote];
}

- (void) refreshTable: (NSInteger) newVote
{
    NSIndexPath *indexPath;
    UITableViewCell *cell;
    
    indexPath = [NSIndexPath indexPathForRow:newVote inSection:0];
    cell = [self.tableView cellForRowAtIndexPath:indexPath];

    //((UIImageView *)cell.accessoryView).image = mkVoteImage(newVote, YES);
    //[cell.accessoryView sizeToFit];    
    cell.textLabel.textColor = [UIColor altBlueColor];    
    cell.imageView.image = mkVoteImage(indexPath.row, YES);
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    indexPath = [NSIndexPath indexPathForRow:self.myVote inSection:0];
    cell = [self.tableView cellForRowAtIndexPath:indexPath];

    //((UIImageView *)cell.accessoryView).image = mkVoteImage(self.myVote, NO);
    //[cell.accessoryView sizeToFit];
    cell.textLabel.textColor = [UIColor darkTextColor];        
    cell.imageView.image = mkVoteImage(indexPath.row, NO);
    cell.accessoryType = UITableViewCellAccessoryNone;        
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 11;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"VoteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];                        
        //cell.accessoryView = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    
    BOOL selected = indexPath.row == _myVote;
    
    cell.textLabel.text = [[SamLibText class] stringForVote:indexPath.row];    
    cell.textLabel.textColor = selected ? [UIColor altBlueColor] : [UIColor darkTextColor];
    cell.imageView.image = mkVoteImage(indexPath.row, selected);
    cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    //((UIImageView *)cell.accessoryView).image = mkVoteImage(indexPath.row, indexPath.row == _myVote);    
    //[cell.accessoryView sizeToFit];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{ 
    return 5;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.myVote = indexPath.row;    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
