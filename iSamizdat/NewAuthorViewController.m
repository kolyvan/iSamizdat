//
//  AddAuthorViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 29.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "NewAuthorViewController.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibModel.h"
#import "WBSuccessNoticeView.h"
#import "WBErrorNoticeView.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface NewAuthorViewController () {
    SamLibAuthor * _author;
    NSArray * _searchResult;
}

@property (nonatomic, strong) IBOutlet UITextField *pathField;
@property (nonatomic, strong) IBOutlet UITextField *searchField;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) IBOutlet UILabel *pathLabel;
@property (nonatomic, strong) IBOutlet UILabel *searchLabel;

@end

@implementation NewAuthorViewController

@synthesize pathField;
@synthesize searchField;
@synthesize tableView;
@synthesize delegate;
@synthesize activityIndicator;
@synthesize doneButton;
@synthesize pathLabel;
@synthesize searchLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = locString(@"Add");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                                    target:self 
                                                                    action:@selector(goDone)];


    UIBarButtonItem *cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self 
                                                                 action:@selector(goCancel)];

    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = self.doneButton;
    
    [self.pathField addTarget:self 
                       action:@selector(pathFieldDoneEditing:) 
             forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [self.searchField addTarget:self 
                         action:@selector(searchFieldDoneEditing:) 
               forControlEvents:UIControlEventEditingDidEndOnExit];

    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.pathLabel.text = locString(@"Enter author's page on samlib.ru");
    self.searchLabel.text = locString(@"Or author's name for search");
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
        
    [activityIndicator stopAnimating]; 
    self.pathField.text = @"";
    self.searchField.text = @"";    
    self.tableView.hidden = YES;
    self.doneButton.enabled = NO;                
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;    
    
    [self.pathField removeTarget:self 
                          action:nil
             forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [self.searchField removeTarget:self 
                            action:nil
                  forControlEvents:UIControlEventEditingDidEndOnExit];
    
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - actions

- (void) goDone
{
    [self dismissViewControllerAnimated:YES 
                             completion:NULL];
    
    if (self.delegate && _author)
        [self.delegate addNewAuthor:_author];
    
    _author = nil;
}

- (void) goCancel
{
    [self dismissViewControllerAnimated:YES 
                             completion:NULL];
 
    _author = nil;        
}

- (void) pathFieldDoneEditing: (id) sender
{
    [sender resignFirstResponder];
    
    NSString *path = [self preparePath: [sender text]];
    
    if (!path.nonEmpty || 
        [path contains: @"."] ||
        [path contains: @"/"]) {

        [[WBErrorNoticeView errorNoticeInView:self.view 
                                        title:locString(@"Invalid path")
                                      message:path] show];
        
        return;
    }
    
    SamLibAuthor *author = [[SamLibModel shared] findAuthor: path];
    if (author) {
        
        [[WBErrorNoticeView errorNoticeInView:self.view 
                                        title:locString(@"Already exists")
                                      message:author.name] show];
        return;
    }
    
    self.pathField.enabled = NO;
    self.searchField.enabled = NO;    
    self.tableView.hidden = YES;    
    [activityIndicator startAnimating];
    _searchResult = nil;
    _author = [[SamLibAuthor alloc] initWithPath:path];
    
    [_author update:^(SamLibAuthor *author, SamLibStatus status, NSString *error) {

        if (self.view.isHidden)
            return;
        
        [activityIndicator stopAnimating];          
        self.pathField.enabled = YES;
        self.searchField.enabled = YES; 
                
        if (status == SamLibStatusFailure) {

            [[WBErrorNoticeView errorNoticeInView:self.view 
                                            title:locString(@"Fetch failure")
                                          message:error] show];
        }
        else {

            self.doneButton.enabled = YES;            
            self.tableView.hidden = NO;
            [self.tableView reloadData];
            
            [[WBSuccessNoticeView successNoticeInView:self.view 
                                            title:locString(@"Fetch success")] show];
            
        }
        
    }]; 
}

- (void) searchFieldDoneEditing: (id) sender
{
    [sender resignFirstResponder];
    
    NSString * name = [sender text];
    
    if (!name.nonEmpty)
        return; 
    
    self.pathField.enabled = NO;
    self.searchField.enabled = NO;    
    self.tableView.hidden = YES; 
    [activityIndicator startAnimating];
    _searchResult = nil;
    _author = nil;
    
    [SamLibAuthor fuzzySearchAuthorByName:name 
                             minDistance1:0.2
                             minDistance2:0.4 
                                    block:^(NSArray *result) {
                                        
                                        if (self.view.isHidden)
                                            return;
                                        
                                        [activityIndicator stopAnimating];          
                                        self.pathField.enabled = YES;
                                        self.searchField.enabled = YES; 
                                        
                                        if (result.nonEmpty) {
                                            
                                            _searchResult = result;
                                            self.tableView.hidden = NO;
                                            [self.tableView reloadData]; 
                                            
                                            NSString *s = KxUtils.format(locString(@"Found: %ld"), result.count); 
                                            [[WBSuccessNoticeView successNoticeInView:self.view 
                                                                                title:s] show];                                            
                                        } else {
                                            
                                            [[WBErrorNoticeView errorNoticeInView:self.view 
                                                                            title:locString(@"Not found") 
                                                                          message:@""] show];
                                        }
                                        
                                    }];

}

- (NSString *) preparePath: (NSString *) path
{    
    if (!path.nonEmpty)
        return nil;
    
    if ([path hasPrefix:@"http://"])
        path = [path drop:@"http://".length];
        
    if ([path hasPrefix:@"samlib.ru"])
        path = [path drop:@"samlib.ru".length];
        
    if ([path hasPrefix:@"zhurnal.lib.ru"])
        path = [path drop:@"zhurnal.lib.ru".length];        
        
    if ([path hasPrefix:@"/"])
        path = [path drop:1];
        
    if (path.length > 2 && 
        [path characterAtIndex:1] == '/' &&
        path.first == [path characterAtIndex:2]) {
        
        path = [path drop:2];
    }
    
    if (path.nonEmpty && 
        path.last == '/') {
        
        path = [path butlast];        
    }
    
    return path;
}


#pragma mark - Table View

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{   
    return _author ? _author.name : locString(@"Search result");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    return _author ? _author.texts.count : _searchResult.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{  
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                      reuseIdentifier:CellIdentifier];        
    }
    
    if (_author) {
           
        SamLibText *text = [_author.texts objectAtIndex:indexPath.row]; 
        cell.textLabel.text = text.title;
        cell.detailTextLabel.text = KxUtils.format(locString(@"Size: %@"), text.size);
        
    } else {

        NSDictionary *dict = [_searchResult objectAtIndex:indexPath.row]; 
        cell.textLabel.text = [dict get:@"name"];
        cell.detailTextLabel.text = [dict get:@"info"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchResult.nonEmpty) {
    
        NSDictionary *dict = [_searchResult objectAtIndex:indexPath.row];
        self.pathField.text = [dict get:@"path"];
    }
}

@end
