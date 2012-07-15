//
//  SearchAuthorViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 16.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "SearchViewController.h"
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
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "AuthorViewController.h"
#import "TextViewController.h"
#import "DDLog.h"

extern int ddLogLevel;

enum {
    SearchNameSelected,
    SearchPageSelected,    
    SearchTextSelected,        
};

@interface SearchViewController () {
    NSArray *_result;
    SamLibSearch *_search;
    BOOL _flagSelectignRow;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) AuthorViewController* authorViewController;
@property (nonatomic, strong) TextViewController* textViewController;

@end

@implementation SearchViewController

@synthesize tableView, searchBar, activityIndicator;
@synthesize authorViewController;
@synthesize textViewController;


- (id) init
{
    self = [super initWithNibName:@"SearchViewController" bundle:nil];
    if (self) {
        self.title = locString(@"Search");
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag: 3];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.searchBar.delegate = self;
    
    self.searchBar.scopeButtonTitles = KxUtils.array(locString(@"Name"), 
                                                     locString(@"Page"), 
                                                     locString(@"Text"), 
                                                     nil);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];    
    [activityIndicator stopAnimating];
    _flagSelectignRow = NO;
    
    if (!_result) // clear table
        [self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated
{    
    //[self.searchBar becomeFirstResponder];
    
    if (![NSStringFromClass([self.parentViewController class]) isEqualToString:@"UIMoreNavigationController"]){
                
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self activateSearchBar: NO];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    [_search cancel];
    _search = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.navigationItem.leftBarButtonItem = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.searchBar.delegate = nil;
    self.authorViewController = nil;
    self.textViewController = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];  
    self.authorViewController = nil;
    self.textViewController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) goDone: (id) found
{    
    if ([found isKindOfClass:[SamLibAuthor class]]) {
    
        if (!self.authorViewController)
            self.authorViewController = [[AuthorViewController alloc] init];        
        self.authorViewController.author = found;
        [self.navigationController pushViewController:self.authorViewController 
                                             animated:YES];
    } else if ([found isKindOfClass:[SamLibText class]]) {
            
        if (!self.textViewController)
            self.textViewController = [[TextViewController alloc] init];        
        self.textViewController.text = found;
        [self.navigationController pushViewController:self.textViewController 
                                             animated:YES];
    }
}

- (void) goCancel
{   
    self.searchBar.text = @"";
    _result = nil;
    [self activateSearchBar: NO];
}

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

- (void) searchAuthor: (NSString *)pattern 
           deepSearch: (BOOL) deepSearch 
{       
    FuzzySearchFlag searchFlag;
    searchFlag = deepSearch ? FuzzySearchFlagAll : FuzzySearchFlagLocal;
    _search = [SamLibSearch searchAuthor:pattern 
                                  byName:YES
                                    flag:searchFlag
                                   block:^(NSArray *result) {
                                       
                                       [self addSearchResult:result 
                                                  deepSearch:deepSearch];                
                                   }];
}

- (void) searchPage: (NSString *)pattern 
           deepSearch: (BOOL) deepSearch 
{      
    
    NSString *path = [self mkSearchPath:pattern];
    if (!path.nonEmpty) {
        
        [[AppDelegate shared] errorNoticeInView:self.view 
                                          title:locString(@"Invalid path") 
                                        message:pattern]; 
        
        if (deepSearch)                
            [activityIndicator stopAnimating];
        
        return;
        
    } else {
        
        pattern = path;
    }
 
    FuzzySearchFlag searchFlag;
    searchFlag = deepSearch ? FuzzySearchFlagCache|FuzzySearchFlagLocal|FuzzySearchFlagDirect : FuzzySearchFlagLocal;    
    _search = [SamLibSearch searchAuthor:pattern 
                                  byName:NO
                                    flag:searchFlag
                                   block:^(NSArray *result) {
                                       
                                       [self addSearchResult:result 
                                                  deepSearch:deepSearch];                
                                   }];
}

- (void) searchText: (NSString *)pattern 
           deepSearch: (BOOL) deepSearch 
{      
    _search = [SamLibSearch searchText:pattern 
                                byName: YES
                                   block:^(NSArray *result) {
                                       
                                       [self addSearchResult:result 
                                                  deepSearch: NO];                                       
                                       
                                   }];
    
    if (deepSearch) {
        
        _search = [SamLibSearch searchText:pattern 
                                    byName: NO
                                     block:^(NSArray *result) {
                                         
                                         [self addSearchResult:result 
                                                    deepSearch: deepSearch];                                       
                                         
                                     }];
    }
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
        
        if (SearchNameSelected == self.searchBar.selectedScopeButtonIndex)            
            [self searchAuthor:pattern deepSearch:deepSearch];            
        else if (SearchPageSelected == self.searchBar.selectedScopeButtonIndex)            
            [self searchPage:pattern deepSearch:deepSearch];                    
        else            
            [self searchText:pattern deepSearch:deepSearch];        
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

#pragma mark - Search bar

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
        
        if (SearchTextSelected != self.searchBar.selectedScopeButtonIndex) {
        
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
            
        } else {
            
            NSString *key = [dict get:@"key"];
            SamLibText *text = [model findTextByKey:key];
            [self goDone: text];         
        }
    }
}

@end
