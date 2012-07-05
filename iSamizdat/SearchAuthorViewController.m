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
#import "SamLibSearch.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface SearchAuthorViewController () {
    NSArray *_result;
    SamLibSearch *_search;
    BOOL _flagSelectignRow;
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
    _result = nil;    
    [self.tableView reloadData];
    self.searchBar.text = @"";
    [activityIndicator stopAnimating];
    _flagSelectignRow = NO;
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

- (void) startSearch
{
    [self.searchBar resignFirstResponder];
    
    _result = nil;
    _search = nil;    
    [self.tableView reloadData];    
        
    NSString * s = self.searchBar.text;    
    
    if (s.nonEmpty) {        
        
        BOOL byName = self.searchBar.selectedScopeButtonIndex == 0;
        
        if (!byName) {
            
            s = [self mkSearchPath:s];            
            if (!s.nonEmpty) {
               
                [[AppDelegate shared] errorNoticeInView:self.view 
                                                  title:locString(@"Invalid path") 
                                                message:@""];                
                return;                
            }
        }  
                
        [activityIndicator startAnimating]; 
        
        _search = [SamLibSearch searchAuthor:s 
                                      byName:byName
                                        flag:FuzzySearchFlagAll
                                       block:^(NSArray *result) {
                                                                                                                                 
                                           [self addSearchResult:result];                
                                       }];
            
    }    
}

- (void) addSearchResult: (NSArray *)found
{   
    if (found.nonEmpty) {
    
        // union and sort
        NSArray *t = [SamLibSearch unionArray:found withArray:_result];    
        _result = KX_RETAIN([SamLibSearch sortByDistance:t]);    
        [self.tableView reloadData];                                            
        
    } else {
    
        [activityIndicator stopAnimating]; 
        
        if (_result.nonEmpty) {                                            
            
            NSString *s = KxUtils.format(locString(@"Found: %ld"), _result.count); 
            [[AppDelegate shared] successNoticeInView:self.view 
                                                title:s];
            
        } else {
            
            [[AppDelegate shared] errorNoticeInView:self.view 
                                              title:locString(@"Not found") 
                                            message:@""];
        }
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
//    [self startSearch];
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
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
   
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
