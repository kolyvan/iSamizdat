//
//  CommentsViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "CommentsViewController.h"
#import "SamLibComments.h"
#import "SamLibComment+IOS.h"
#import "SamLibAuthor+IOS.h"
#import "SamLibText.h"
#import "CommentCell.h"

@interface CommentsViewController () {
    BOOL _needReload;
    id _version;
}

@end

@implementation CommentsViewController

@synthesize comments = _comments;

- (void) setComments:(SamLibComments *)comments
{
    if (comments != _comments || 
        ![comments.version isEqual:_version]) {        
        
        _version = comments.version;
        _comments = comments;
        _needReload = YES;        
    }
}

- (id) init
{
    return [self initWithNibName:@"CommentsViewController" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                               target:self 
                                                                               action:@selector(goAddPost)];
    
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void) viewWillAppear:(BOOL)animated 
{    
    [super viewWillAppear:animated];
    if (_needReload) {
        _needReload = NO;           
        self.title = _comments.text.author.shortName;        
        //[self prepareData];       
        [self.tableView reloadData];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.navigationItem.rightBarButtonItem = nil;
}

- (NSDate *) lastUpdateDate
{
    return _comments.timestamp;
}

- (void) refresh: (void(^)(SamLibStatus status, NSString *error)) block
{
    [_comments update:YES block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
        
        block(status, error);        
        
    }];
}

- (void) goAddPost
{
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _comments.all.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CommentCell";
    
    CommentCell *cell = (CommentCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[CommentCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                  reuseIdentifier:CellIdentifier 
                                       controller:self];
    }
    
    cell.comment = [_comments.all objectAtIndex:indexPath.row];    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SamLibComment *comment = [_comments.all objectAtIndex:indexPath.row];    
    
    return [CommentCell heightForComment:comment 
                               withWidth:tableView.frame.size.width];
    
}

@end
