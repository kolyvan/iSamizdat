//
//  SearchAuthorViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 16.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "SearchViewController.h"
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
#import "SamLibSearch.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface SearchViewController () {
    NSArray *_result;
    SamLibSearch *_search;
    BOOL _flagSelectignRow;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation SearchViewController

@synthesize tableView, searchBar, activityIndicator, delegate;

- (id) init
{
    return [self initWithNibName:@"SearchViewController" bundle:nil];
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
    
//    self.navigationController
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //_result = nil;    
    [self.tableView reloadData];
    self.searchBar.text = @"";
    [activityIndicator stopAnimating];
    _flagSelectignRow = NO;
}

- (void) viewDidAppear:(BOOL)animated
{
  //  [self activateSearchBar: YES];
    [self.searchBar becomeFirstResponder];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self activateSearchBar: NO];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [_search cancel];
    _search = nil;
    _result = nil;    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.navigationItem.leftBarButtonItem = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.searchBar.delegate = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];  
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
//    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}

- (void) goDone: (SamLibAuthor *)author
{
    [self dismissViewControllerAnimated:YES 
                             completion:NULL];
    
   // if (self.delegate && author)
   //     [self.delegate searchAuthorResult:author];
}

- (void) goCancel
{   
    [self dismissViewControllerAnimated:YES 
                             completion:NULL];
}

- (NSString *) mkSearchPath: (NSString *)path
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
                
        return nil;
    }
    
    return path;
}


#pragma mark - Search bar

- (void) activateSearchBar: (BOOL) activate
{
    if (activate) {
      
        [self.searchBar becomeFirstResponder];                
        self.searchBar.showsScopeBar = YES;
        
    } else {

        [self.searchBar resignFirstResponder];        
        self.searchBar.showsScopeBar = NO;        
    }
    
    [self.searchBar sizeToFit];
    CGFloat h = self.searchBar.frame.size.height;
    CGRect frame = self.tableView.frame;
    frame.size.height += frame.origin.y - h;     
    frame.origin.y = h;     
    self.tableView.frame = frame;    
}

- (void) searchAuthor: (NSString *)pattern 
           deepSearch: (BOOL) deepSearch 
{   
    BOOL byName = YES;
    
    if (pattern.first > 96 && pattern.first < 123) {
        
        NSString *path = [self mkSearchPath:pattern];
        if (!path.nonEmpty) {
            
            [[AppDelegate shared] errorNoticeInView:self.view 
                                              title:locString(@"Invalid path") 
                                            message:pattern]; 
            
            if (deepSearch)                
                [activityIndicator stopAnimating];
            
            return;

        } else {
            
            byName = NO;
            pattern = path;
        }
    }
  
    _search = [SamLibSearch searchAuthor:pattern 
                                  byName:byName
                                    flag:deepSearch ? FuzzySearchFlagAll : FuzzySearchFlagLocal
                               block:^(NSArray *result) {
                                   
                                   [self addSearchResult:result 
                                              deepSearch: deepSearch];                
                               }];


}

- (void) startSearch: (NSString *)pattern 
          deepSearch: (BOOL) deepSearch 
{
    _result = nil;
    [_search cancel];
    _search = nil;    
    [self.tableView reloadData];   
    
    if (deepSearch) {
        
        [activityIndicator startAnimating];  
        [self activateSearchBar: NO];        
    }
    
    if (pattern.nonEmpty) {        
        
        if (0 == self.searchBar.selectedScopeButtonIndex)  {
            
            [self searchAuthor:pattern deepSearch:deepSearch];
            
        } else {
        }
    }    
}

- (void) addSearchResult: (NSArray *)found 
              deepSearch: (BOOL) deepSearch 
{   
    if (found.nonEmpty) {
    
        // union and sort
        NSArray *t = [SamLibSearch unionArray:found withArray:_result];    
        _result = KX_RETAIN([SamLibSearch sortByDistance:t]);    
        [self.tableView reloadData];                                            
        
    } else {
        
        if (deepSearch) {
            
            [activityIndicator stopAnimating];             
                    
            if (!_result.nonEmpty) {                                            
                                
                [[AppDelegate shared] errorNoticeInView:self.view 
                                                  title:locString(@"Not found") 
                                                message:@""];
            }
        }
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{    
    [self activateSearchBar: YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self startSearch: searchText deepSearch:NO]; 
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)sender
{     
    [self startSearch: sender.text deepSearch:YES]; 
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{    
    [self goCancel];
}

#pragma mark - Table view

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{   
//    return _author ? _author.name : locString(@"Search result");
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    return _result.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{  
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];        
    }
    
    NSDictionary *dict = [_result objectAtIndex:indexPath.row]; 
    
    cell.textLabel.text = [dict get:@"name"];
    cell.detailTextLabel.text = [dict get:@"info"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
   
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_result.nonEmpty && !_flagSelectignRow) {
        
        _flagSelectignRow = YES;
        
        NSDictionary *dict = [_result objectAtIndex:indexPath.row];
        
        SamLibModel *model = [SamLibModel shared];
        
        NSString *from = [dict get:@"from"];
        NSString *path = [dict get:@"path"]; 
        
        if ([from isEqualToString:@"local"]) {
            
            [self goDone: [model findAuthor:path]];                     
            
        } else {
            
            SamLibAuthor *author = [SamLibAuthor fromDictionary:dict withPath:path];                        
            [model addAuthor:author];                          
            [self goDone: [model findAuthor:path]];                     
            // [appDelegate reload: nil];
        }
        
    }
}

@end
