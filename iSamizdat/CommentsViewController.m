//
//  CommentsViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "CommentsViewController.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "SamLibComments.h"
#import "SamLibComment+IOS.h"
#import "SamLibAuthor+IOS.h"
#import "SamLibText.h"
#import "CommentCell.h"
#import "PostViewController.h"


@interface ActionSheetWithComment : UIActionSheet
@property (readwrite, strong) SamLibComment * comment;
@end

@implementation ActionSheetWithComment
@synthesize comment;
@end

////

@interface CommentsViewController () {
    BOOL _needReload;
    id _version;
    PostData *_postData;
}

@property (nonatomic, strong) PostViewController *postViewController;

@end

@implementation CommentsViewController

@synthesize comments = _comments;
@synthesize postViewController;

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
                                                                               action:@selector(replyPost)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void) viewWillAppear:(BOOL)animated 
{    
    [super viewWillAppear:animated];
    if (_needReload) {
        _needReload = NO;           
        self.title = _comments.text.title;
        //self.title = _comments.text.author.shortName;        
        //[self prepareData];       
        [self.tableView reloadData];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.navigationItem.rightBarButtonItem = nil;    
    self.postViewController = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.postViewController = nil;    
}

- (NSDate *) lastUpdateDate
{
    return _comments.timestamp;
}

- (void) refresh: (void(^)(SamLibStatus status, NSString *message)) block
{
    if (_postData) {
        
        if (_postData.message != nil) {
        
            [_comments post:_postData.message
                      msgid:_postData.msgid
                    isReply:!_postData.isEdit
                      block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
                          
                          NSString *message;
                          if (status == SamLibStatusSuccess)                                       
                              message = locString(@"Send comment");
                          else if (status == SamLibStatusFailure) 
                              message = error;
                              
                          block(status, message);
                      }];
        } else {
            
            [_comments deleteComment:_postData.msgid 
                               block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
                                   
                                   NSString *message;
                                   if (status == SamLibStatusSuccess)                                       
                                       message = locString(@"Deleted comment");
                                   else if (status == SamLibStatusFailure) 
                                       message = error;
                                   
                                  block(status, message);                                   
                               }];
        }        
        
        _postData = nil;
        
    } else {
    
        [_comments update:YES 
                    block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
            
                        NSString *message;
                        if (status == SamLibStatusSuccess)                            
                            message = KxUtils.format(locString(@"New comments:%ld"), comments.numberOfNew);
                        else if (status == SamLibStatusFailure)                            
                            message = error;
                        
                        block(status, message);            
        }];        
    }
}

- (void) replyPost:(SamLibComment *)comment 
            isEdit: (BOOL) isEdit
{
    if (!self.postViewController) {
        self.postViewController = [[PostViewController alloc] init];
        self.postViewController.delegate = self;
    }
    
    self.postViewController.comment = comment; 
    self.postViewController.isEdit = isEdit;
    
    [self.navigationController pushViewController:self.postViewController 
                                         animated:YES];
}

- (void) replyPost
{   
    [self replyPost:nil isEdit:NO];
}

- (void) replyPost: (SamLibComment *) comment
{
    [self replyPost:comment isEdit:NO];
}

- (void) editPost: (SamLibComment *) comment
{
    [self replyPost:comment isEdit:YES];    
}

- (void) deletePost: (SamLibComment *) comment
{
    ActionSheetWithComment *actionSheet;
    actionSheet = [[ActionSheetWithComment alloc] initWithTitle:locString(@"Are you sure?")
                                                       delegate:self
                                              cancelButtonTitle:locString(@"Cancel") 
                                         destructiveButtonTitle:locString(@"Delete") 
                                              otherButtonTitles:nil];
    actionSheet.comment = comment;    
    [actionSheet showInView:self.view];
}

- (void) sendPost: (PostData *) post
{   
    _postData = post;        
    //[self.pullToRefreshView startLoadingAndForceExpand];      
    [self forceRefresh];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        
        SamLibComment *comment = ((ActionSheetWithComment *)actionSheet).comment;
        
        _postData = [[PostData alloc] init];
        _postData.msgid = comment.msgid;
        //[self.pullToRefreshView startLoadingAndForceExpand];          
        [self forceRefresh];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView 
{
    [self.tableView setEditing:NO animated:NO]; // cancel any swiped cell
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
                                  reuseIdentifier:CellIdentifier];
    }
    
    cell.delegate = self;
    cell.comment = [_comments.all objectAtIndex:indexPath.row];    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SamLibComment *comment = [_comments.all objectAtIndex:indexPath.row];    
    
    return [CommentCell heightForComment:comment 
                               withWidth:tableView.frame.size.width];
    
}

- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // just leave this method empty
}


@end
