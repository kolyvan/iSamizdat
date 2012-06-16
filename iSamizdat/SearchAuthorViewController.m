//
//  SearchAuthorViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 16.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "SearchAuthorViewController.h"
#import "SamLibAuthor.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSObject+Kolyvan.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "AppDelegate.h"
#import "SamLibModel.h"
#import "SamLibAgent.h"

@interface SearchAuthorViewController () {
    NSArray *_searchResult;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation SearchAuthorViewController

@synthesize tableView, searchBar, activityIndicator, delegate;

- (id) init
{
    return [self initWithNibName:@"SearchAuthorViewController" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self 
                                                                 action:@selector(goCancel)];
    
    self.navigationItem.leftBarButtonItem = cancelButton;

    
    self.title = locString(@"Search");
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.searchBar.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _searchResult = nil;    
    [self.tableView reloadData];
    self.searchBar.text = @"";
    [activityIndicator stopAnimating]; 
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    _searchResult = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.navigationItem.leftBarButtonItem = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.searchBar.delegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) goDone: (SamLibAuthor *)author
{
    [self dismissViewControllerAnimated:YES 
                             completion:NULL];
    
    if (self.delegate && author)
        [self.delegate searchAuthorResult:author];
    
}

- (void) goCancel
{
    SamLibAgent.cancelAll();
    
    [self dismissViewControllerAnimated:YES 
                             completion:NULL];
}

- (void) goSearchByName: (NSString *)name
{   
    [SamLibAuthor fuzzySearchAuthorByName:name 
                             minDistance1:0.2
                             minDistance2:0.4 
                                    block:^(NSArray *result) {  
                                        
                                        if (self.view.isHidden)
                                            return;                                        
                                        
                                        [self finishSearch:result];            
                                    }];
}

- (void) goSearchByPath: (NSString *)path
{       
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

    if ([path contains: @"."] ||
        [path contains: @"/"]) {
        
        //locString(@"Invalid path")        
        [self finishSearch:nil];
        return;
    }
    
    SamLibAuthor *author = [[SamLibModel shared] findAuthor: path];
    if (author) {
                
        [self finishSearchWithAuthor:author];        
        return;
    }
    
    // the block will keep the reference to authors object
    author = [[SamLibAuthor alloc] initWithPath:path];
    
    [author update:^(SamLibAuthor *unused, SamLibStatus status, NSString *error) {
        
        if (self.view.isHidden)
            return;

        if (status == SamLibStatusSuccess) {
            
            [self finishSearchWithAuthor:author];
            
        } else {
            
            [self finishSearch:nil];
            
            // todo: fuzzy search
        }        

    }]; 
}


#pragma mark - Search bar

- (void) startSearch
{
    [self.searchBar resignFirstResponder];
        
    NSString * s = self.searchBar.text;    
    if (s.nonEmpty) {        
        
        _searchResult = nil;
        [self.tableView reloadData];    
        [activityIndicator startAnimating];
        
        if (self.searchBar.selectedScopeButtonIndex == 0)        
            [self goSearchByName: s];
        else
            [self goSearchByPath: s];
    }    
}

- (void) finishSearchWithAuthor: (SamLibAuthor *) author
{
    NSDictionary *dict = KxUtils.dictionary(
                                            author.path, @"path",
                                            author.name, @"name",
                                            author.title, @"info",                                                                                        
                                            nil);
    [self finishSearch:[NSArray arrayWithObject:dict]];
}

- (void) finishSearch: (NSArray *)result
{
    [activityIndicator stopAnimating]; 
    
    if (result.nonEmpty) {                                            
        
        _searchResult = result;
        [self.tableView reloadData];                                            
        
        NSString *s = KxUtils.format(locString(@"Found: %ld"), result.count); 
        [[AppDelegate shared] successNoticeInView:self.view 
                                            title:s];
        
    } else {
        
        [[AppDelegate shared] errorNoticeInView:self.view 
                                          title:locString(@"Not found") 
                                        message:@""];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self startSearch];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)sender
{
    [self startSearch]; 
}

#pragma mark - Table view

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{   
//    return _author ? _author.name : locString(@"Search result");
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    return _searchResult.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{  
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];        
    }
    
    NSDictionary *dict = [_searchResult objectAtIndex:indexPath.row]; 
    
    cell.textLabel.text = [dict get:@"name"];
    cell.detailTextLabel.text = [dict get:@"info"];
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
   
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchResult.nonEmpty) {

        
        
    }
}

@end
