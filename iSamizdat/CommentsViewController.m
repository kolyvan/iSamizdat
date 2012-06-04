//
//  CommentsViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "CommentsViewController.h"
#import "KxMacros.h"
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

- (void) refresh: (void(^)(SamLibStatus status, NSString *error)) block
{
    [_comments update:YES block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
        
        block(status, error);        
        
    }];
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

- (void) sendPost: (NSString *) message
          comment: (NSString *) msgid 
           isEdit: (BOOL) isEdit
{ 
    
    [_comments post:message
              msgid:msgid
            isReply:!isEdit
              block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
                  
                  if (status == SamLibStatusSuccess)
                      [self.tableView reloadData];
                  
              }];
    
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        
        SamLibComment *comment = ((ActionSheetWithComment *)actionSheet).comment;
        
        [_comments deleteComment:comment.msgid 
                           block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
                               
                               if (status == SamLibStatusSuccess)
                                   [self.tableView reloadData];
                               
                           }];        
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
