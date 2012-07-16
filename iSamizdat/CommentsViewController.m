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
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSData+Kolyvan.h"
#import "SamLibComments.h"
#import "SamLibComment+IOS.h"
#import "SamLibAuthor+IOS.h"
#import "SamLibText.h"
#import "SamLibModel.h"
#import "SamLibHistory.h"
#import "SamLibModerator.h"
#import "CommentCell.h"
#import "PostViewController.h"
#import "AuthorViewController.h"

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
    UISwipeGestureRecognizer *_gestureRecognizer;
    KX_WEAK CommentCell *_swipeCell; 
}

@property (nonatomic, strong) PostViewController *postViewController;
@property (nonatomic, strong) AuthorViewController *authorViewController;

@end

@implementation CommentsViewController

@synthesize comments = _comments;
@synthesize postViewController, authorViewController;

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
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
                                                                               target:self 
                                                                               action:@selector(replyPost)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    
    _gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                  action:@selector(handleSwipe:)];    
    
    _gestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight  | UISwipeGestureRecognizerDirectionLeft; 
    [self.tableView addGestureRecognizer:_gestureRecognizer];  
}

- (void) viewWillAppear:(BOOL)animated 
{    
    [super viewWillAppear:animated];
    if (_needReload) {
        _needReload = NO; 
        [self.tableView reloadData];        
    } 
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self cancelSwipeAnimated: NO];
    
    if (_comments.all.count > 0)
        [[SamLibHistory shared] addComments:_comments];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.navigationItem.rightBarButtonItem = nil;    
    self.postViewController = nil;
    self.authorViewController = nil;
    
    [self.tableView removeGestureRecognizer:_gestureRecognizer];
    _gestureRecognizer = nil;   
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.postViewController = nil; 
    self.authorViewController = nil;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)sender 
{   
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        CGPoint pt = [sender locationInView: self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: pt];        
        CommentCell *cell = (CommentCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                
        CommentCell *swipeCell = _swipeCell;
        
        if (swipeCell == cell) {
            
            [swipeCell swipeCloseAnimated:YES];
            _swipeCell = nil;
            
        } else {
                           
            [swipeCell swipeCloseAnimated:YES];
            
            if (cell.comment.deleteMsg.nonEmpty) {

                _swipeCell = nil;
                
            } else {
            
                [cell swipeOpen];
                _swipeCell = cell;
            }            
        }
    } 
}

- (void) cancelSwipeAnimated: (BOOL) animated
{
    CommentCell *swipeCell = _swipeCell;
    if (swipeCell)
        [swipeCell swipeCloseAnimated:animated];
    _swipeCell = nil;
}

- (NSDate *) lastUpdateDate
{
    return _comments.all.count > 0 ?  _comments.timestamp : nil;
}

- (void) refresh: (void(^)(SamLibStatus status, NSString *message)) block
{
    [self cancelSwipeAnimated:NO];
    
    if (_postData) {
        
        if (_postData.message != nil) {
        
            [_comments post:_postData.message
                      msgid:_postData.msgid
                    isReply:!_postData.isEdit
                      block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
                          
                          NSString *message;
                          if (status == SamLibStatusSuccess)  {                                      
                              message = locString(@"Send comment");
                              if (comments.numberOfNew > 0)
                                  [self filterComments];
                          }
                          else if (status == SamLibStatusFailure) 
                              message = error;
                              
                          block(status, message);
                      }];
        } else {
            
            [_comments deleteComment:_postData.msgid 
                               block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
                                   
                                   NSString *message;
                                   if (status == SamLibStatusSuccess)  {                                     
                                       message = locString(@"Deleted comment");
                                       if (comments.numberOfNew > 0)
                                           [self filterComments];
                                   }
                                   else if (status == SamLibStatusFailure) 
                                       message = error;
                                   
                                  block(status, message);                                   
                               }];
        }        
        
        _postData = nil;
        
    } else {
    
        [_comments update:NO 
                    block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
            
                        NSString *message;
                        if (status == SamLibStatusSuccess)  {                          
                            if (comments.numberOfNew > 0) {
                                
                                message = KxUtils.format(locString(@"New comments:%ld"), comments.numberOfNew);
                                [self filterComments];
                                
                            } else {
                                
                                status = SamLibStatusNotModifed;
                            }
                        }
                        else if (status == SamLibStatusFailure)                            
                            message = error;
                        
                        block(status, message);            
        }];        
    }
}

- (void) filterComments
{    
    SamLibModerator *moderator = [SamLibModerator shared];
             
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSData *d = [NSData dataWithContentsOfFile:KxUtils.pathForResource(@"censored.bin")];
        NSString *s = [NSString stringWithUTF8String:d.gunzip.bytes];
        NSArray *a = s.split;
        if (a.nonEmpty) {
            [moderator registerLinkToPattern:@"censored" pattern:a];
        }            
    });
    
    NSString *path = [_comments.text makeKey:@"/"]; 
    for (SamLibComment *comment in _comments.all) { 
        
        if (comment.isNew && comment.msgid.nonEmpty) {
            
            if ([moderator testForBan:comment withPath:path] != nil)
                [_comments setHiddenFlag:YES forComment:comment];
        }
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
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void) goAuthor: (NSString *) path
{
    SamLibModel *model = [SamLibModel shared];
    SamLibAuthor *author = [model findAuthor:path];
    if (!author) {
    
        author = [[SamLibAuthor alloc] initWithPath:path];
        [model addAuthor:author];
    }
        
    if (!self.authorViewController) {
        self.authorViewController = [[AuthorViewController alloc] init];
    }
    self.authorViewController.author = author;
    [self.navigationController pushViewController:self.authorViewController 
                                         animated:YES];
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
    [self cancelSwipeAnimated: YES];
}

- (void) toggleCommentCell: (CommentCell *)cell
{
    SamLibComment *comment = cell.comment;    
    [_comments setHiddenFlag:!comment.isHidden forComment:comment];
    
    NSIndexPath * indexPath = [self.tableView indexPathForCell: cell];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:YES];

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
    
    SamLibComment *comment = [_comments.all objectAtIndex:indexPath.row];       
    cell.delegate = self;
    cell.comment = comment;    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    SamLibComment *comment = [_comments.all objectAtIndex:indexPath.row];  
    return [CommentCell heightForComment:comment 
                               withWidth:tableView.frame.size.width];
}

@end
