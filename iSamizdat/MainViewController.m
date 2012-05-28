//
//  AuthorsViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 28.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "MainViewController.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "NSArray+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "KxTuple2.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface MainViewController () {
    NSInteger _version;
    BOOL _tableLoaded;
}

@property (nonatomic, strong) NSArray *content;
@property (nonatomic, strong) NSArray *ignored;
@property (nonatomic, strong) NSArray *authors;
@property (nonatomic, strong) SSPullToRefreshView *pullToRefreshView;

@end

@implementation MainViewController

@synthesize content = _content;
@synthesize ignored = _ignored;
@synthesize authors = _authors;
@synthesize pullToRefreshView = _pullToRefreshView;

static UIFont* systemFont14 = nil;

+ (void)initialize
{
	if (self == [MainViewController class])
	{		
		systemFont14 = [UIFont systemFontOfSize:14];     
	}
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = locString(@"Samizdat");
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"emblem-system.png"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self 
                                                                      action:@selector(goSettings)];


    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                               target:self 
                                                                               action:@selector(goAddAuthor)];

    self.navigationItem.leftBarButtonItem = settingsButton;    
    self.navigationItem.rightBarButtonItem = addButton;
    
    self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView delegate:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.content = nil;
    self.ignored = nil;
    self.authors = nil;
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    self.pullToRefreshView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) viewWillAppear:(BOOL)animated
{
    [self prepareData];    
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];        
}

#pragma mark - private functions

- (void) prepareData
{
    SamLibModel *model = [SamLibModel shared];
    
    if (_version != model.version ||
        _authors == nil ||
        _content == nil ||
        _ignored == nil) {
        
        _version = model.version;
        
        NSArray *a = [SamLibModel shared].authors;
        KxTuple2 * result = [a partition:^(id elem) {
            return ((SamLibAuthor *)elem).ignored;
        }];    
        
        self.ignored = result.first;  
        self.authors = result.second;        
        self.content = [self mkContent];        
        [self.tableView reloadData]; 
    }
}

- (NSArray *) mkContent
{
    NSMutableArray * ma = [NSMutableArray array];            
    for (SamLibAuthor *author in self.authors) {            
        [ma push:author];    
        for (SamLibText *text in author.texts)
            if (text.changedSize)
                [ma push:text];
    }
    return ma;
}

- (void) goAddAuthor
{
}

- (void) goSettings
{
}

#pragma mark - refresh 



- (void) refresh
{           
    __block NSInteger count = _authors.count;
    __block SamLibStatus reloadStatus = SamLibStatusNotModifed;
    __block NSString *lastError = nil;
    
    [self.pullToRefreshView startLoading];
    
    for (SamLibAuthor *author in _authors) {
        
        [author update:^(SamLibAuthor *author, SamLibStatus status, NSString *error) {
            
            //DDLogInfo(@"reload author %@ %ld", author.path, status); 
            
            if (status == SamLibStatusSuccess) {
                reloadStatus = SamLibStatusSuccess;
                // [self reloadTableView];
            }
            
            if (status == SamLibStatusFailure &&
                ![error isEqualToString: lastError]) {
                
                // todo: show failure
                // "@"reload failure\n%@", error;                    
                lastError = error;
            }
            
            if (--count == 0) {
                
                if (reloadStatus == SamLibStatusSuccess) {
                    
                    self.content = [self mkContent];  
                    [self.tableView reloadData];                        
                    //DDLogInfo(@"reload table %@", [self class]); 
                }
                
                [self.pullToRefreshView finishLoading];
                lastError = nil;
            }
        }];
    } 
}

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view 
{
    if (self.authors.nonEmpty) {
    
        NSDate *date = [self.authors fold:nil with:^id(id acc, id elem) {
            NSDate *l = acc, *r = ((SamLibAuthor *)elem).timestamp;
            return [r laterDate: l];
        }];
        
        [self.pullToRefreshView.contentView setLastUpdatedAt:date 
                                       withPullToRefreshView:view];        
    }
    
    [self refresh];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{    
    if (section == 1)
        return locString(@"Authors");
    
    else if (section == 2)
        return locString(@"Ignored");
    
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 1;
    
    else if (section == 1)
        return self.content.count;
    
    else if (section == 2)
        return self.ignored.count;

    return 0;
}

- (UITableViewCell *) mkMainCell
{
    static NSString *CellIdentifier = @"MainCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (UITableViewCell *) mkTextCell
{
    static NSString *CellIdentifier = @"TextCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.font = systemFont14;
        cell.textLabel.font = systemFont14;        
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (indexPath.section == 0) {
        
        UITableViewCell *cell = [self mkMainCell];
        cell.textLabel.text = locString(@"Favorites");
        return cell;
    }
        
    if (indexPath.section == 1) {        
        
        id obj = [self.content objectAtIndex:indexPath.row]; 
        
        if ([obj isKindOfClass:[SamLibText class]]) {
            
            UITableViewCell *cell = [self mkTextCell];
            SamLibText *text = obj;
            cell.detailTextLabel.text = KxUtils.format(@"%+ldk", text.deltaSize);
            cell.textLabel.text = text.title;
            return cell;            
        }
        
        if ([obj isKindOfClass:[SamLibAuthor class]]) {
            
            UITableViewCell *cell = [self mkMainCell];
            SamLibAuthor *author = obj;
            cell.textLabel.text = author.name.nonEmpty ? author.name : author.path;
            return cell;
        }
    } 
    
    if (indexPath.section == 2) {        
        
        UITableViewCell *cell = [self mkMainCell];
        SamLibAuthor *author = [self.ignored objectAtIndex:indexPath.row];    
        cell.textLabel.text = author.name.nonEmpty ? author.name : author.path;
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{       
    if (indexPath.section == 1) {
        id obj = [self.content objectAtIndex:indexPath.row];         
        if ([obj isKindOfClass:[SamLibText class]]) {         
            return systemFont14.lineHeight + 16;
        }        
    }    
    return self.tableView.rowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        id obj = [self.content objectAtIndex:indexPath.row];         
        if ([obj isKindOfClass:[SamLibText class]]) {         
            return 1;
        }        
    }    
    return 0;
}

@end
