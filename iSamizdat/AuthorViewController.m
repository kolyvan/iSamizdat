//
//  AuthorViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 29.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "AuthorViewController.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibAuthor+IOS.h"
#import "SamLibText+IOS.h"
#import "KxMacros.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "TextViewController.h"
#import "AppDelegate.h"

@interface AuthorViewController () {
    BOOL _needReload;
    id _version;
    NSArray *_sections;
}
@property (nonatomic, strong) TextViewController *textViewController;
@property (nonatomic, strong) SSPullToRefreshView *pullToRefreshView;
@property (nonatomic, strong) UIBarButtonItem *stopButton;
@end

@implementation AuthorViewController

@synthesize author = _author;
@synthesize textViewController;
@synthesize pullToRefreshView;
@synthesize stopButton;

- (void) setAuthor:(SamLibAuthor *)author 
{
    if (author != _author || 
        ![author.version isEqual:_version]) {        
        
        _version = author.version;
        _author = author;
        _needReload = YES;
    }
}

static UIFont* boldSystemFont = nil;

+ (void)initialize
{
	if (self == [AuthorViewController class])
	{		
		boldSystemFont = [UIFont boldSystemFontOfSize:16];     
	}
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {     
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                   style:UIBarButtonItemStylePlain 
                                                                  target:nil
                                                                  action:nil];
    
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
                                                                                target:self 
                                                                                action:@selector(goInfo)];

    
    self.stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop 
                                                                    target:self 
                                                                    action:@selector(goStop)];
    
    self.navigationItem.backBarButtonItem = backButton;
    self.navigationItem.rightBarButtonItem = infoButton;    
    
    self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView 
                                                                    delegate:self];
}

- (void) viewWillAppear:(BOOL)animated 
{    
    [super viewWillAppear:animated];
    if (_needReload) {
        _needReload = NO;
        self.title = _author.name;
        self.navigationItem.backBarButtonItem.title = [_author.name split].first;        
        [self prepareData];
        [self.tableView reloadData];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.navigationItem.backBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    self.pullToRefreshView = nil;
    self.stopButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - private

- (void) prepareData
{
    NSMutableDictionary * sections = [NSMutableDictionary dictionary];
    
    for (SamLibText *text in _author.texts) {
        
        NSString *section = nil;
        
        NSString *group = text.group;
        BOOL subGroup = NO;
        
        if (group.nonEmpty) {
            section = group; 
            subGroup = group.first == '@';
        }
        else if (text.type.nonEmpty)
            section = text.type; 
        else
            section = @"";
                
        if (subGroup)
            section = @"";
        
        NSMutableArray * ma = [sections get:section orSet:^{ 
            return [NSMutableArray array]; 
        }];
        
        if (subGroup)  {
            
            if (![ma containsObject:text.groupEx])
                [ma push: text.groupEx];     
            
        } else {
            
            [ma push: text];        
        }
    }
    
    _sections = sections.allValues;
}

- (void) goInfo
{
    
}

- (void) goStop
{
    SamLibAgent.cancelAll();
    [self.pullToRefreshView finishLoading];
    self.navigationItem.rightBarButtonItem = nil;    
}

- (void) refresh
{
    self.navigationItem.rightBarButtonItem = self.stopButton;
    [self.pullToRefreshView startLoading];
    
    [_author update:^(SamLibAuthor *author, SamLibStatus status, NSString *error) {
        
        [self.pullToRefreshView finishLoading];
        self.navigationItem.rightBarButtonItem = nil;

        author.lastError = nil;                
        
        if (status == SamLibStatusFailure) {
            
            author.lastError = error;
            
            [self performSelector:@selector(showNoticeAboutReloadResult:) 
                       withObject:error
                       afterDelay:0.3];
            
        } 
        
        if (status == SamLibStatusSuccess) {            
            
            [self prepareData];
            [self.tableView reloadData];
            
            [self performSelector:@selector(showNoticeAboutReloadResult:) 
                       withObject:nil
                       afterDelay:0.3];
        }
    }];
}

- (void) showNoticeAboutReloadResult: (NSString *) error
{
    if (error) {
        
        [[AppDelegate shared] errorNoticeInView:self.view 
                                          title:locString(@"Reload failure") 
                                        message:error];        
    } else {
        
        [[AppDelegate shared] successNoticeInView:self.view 
                                            title:locString(@"Reload success")];
    }
}

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view 
{    
    [self.pullToRefreshView.contentView setLastUpdatedAt:_author.timestamp 
                                   withPullToRefreshView:view]; 
    
    [self refresh];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[_sections objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{   
    NSArray *a = [_sections objectAtIndex:section];
    id first = a.first;
    if ([first isKindOfClass:[SamLibText class]]) {
        SamLibText * text = first;
        return text.group.nonEmpty ? text.groupEx : text.type;
    }    
    return @"";
}

- (id) mkCell: (NSString *) cellIdentifier
    withStyle: (UITableViewCellStyle) style
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier];                
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSArray *section = [_sections objectAtIndex:indexPath.section];    
    id obj = [section objectAtIndex:indexPath.row]; 
    
    if ([obj isKindOfClass:[SamLibText class]]) {
        
        SamLibText* text = obj;        
        UITableViewCell *cell = [self mkCell: @"TextCell" withStyle:UITableViewCellStyleDefault];        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = text.title;
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.font = boldSystemFont;
        
        if (text.changedSize) {
            
            cell.imageView.image = [UIImage imageNamed:@"size_changed.png"];
            
        } else if (text.changedComments) {
            
            cell.imageView.image = [UIImage imageNamed:@"comment.png"];     
            
        } else {
            
            cell.imageView.image = text.favoritedImage;
        }

        return cell;        
    } 
    
    if ([obj isKindOfClass:[NSString class]]) {
        
        UITableViewCell *cell = [self mkCell: @"GroupCell" withStyle:UITableViewCellStyleDefault];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;        
        cell.textLabel.text = obj;  
        //cell.textLabel.font = boldSystemFont;
        return cell;
    }
    
    return nil;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *section = [_sections objectAtIndex:indexPath.section];    
    id obj = [section objectAtIndex:indexPath.row]; 
    
    if ([obj isKindOfClass:[SamLibText class]]) {

        if (!self.textViewController) {
            self.textViewController = [[TextViewController alloc] initWithNibName:@"TextViewController" 
                                                                           bundle:nil];
        }
        
        self.textViewController.text = obj;
        [self.navigationController pushViewController:self.textViewController 
                                             animated:YES]; 
    }
}

@end
