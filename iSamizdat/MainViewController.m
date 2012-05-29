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
#import "SamLibAgent.h"
#import "SamLibAuthor+IOS.h"
#import "NSArray+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "KxTuple2.h"
#import "AppDelegate.h"
#import "DDLog.h"

extern int ddLogLevel;

typedef enum {
    
    FavoritesSectionNumber  = 0,
    AuthorSectionNumber     = 1,
    IgnoredSectionNumber    = 2,    
    
} SectionNumber;

@interface MainViewController () {
    NSInteger _version;
    BOOL _tableLoaded;
}

@property (nonatomic, strong) NSArray *content;
@property (nonatomic, strong) NSArray *ignored;
@property (nonatomic, strong) NSArray *authors;
@property (nonatomic, strong) SSPullToRefreshView *pullToRefreshView;
@property (nonatomic, strong) UIBarButtonItem *addButton;
@property (nonatomic, strong) UIBarButtonItem *stopButton;
@property (nonatomic, strong) NewAuthorViewController *addAuthorViewController;

@end

@implementation MainViewController

@synthesize content;
@synthesize ignored;
@synthesize authors;
@synthesize pullToRefreshView;
@synthesize addButton, stopButton;
@synthesize addAuthorViewController;

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


    self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                   target:self 
                                                                   action:@selector(goAddAuthor)];
    
    self.stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop 
                                                                    target:self 
                                                                    action:@selector(goStop)];


    self.navigationItem.leftBarButtonItem = settingsButton;    
    self.navigationItem.rightBarButtonItem = self.addButton;
    
    self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView 
                                                                    delegate:self];
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
    self.addButton = nil;
    self.stopButton = nil;    
    self.addAuthorViewController = nil;
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
    
    self.addAuthorViewController = nil;
}

#pragma mark - private functions

- (BOOL) hasFavorites
{
    NSArray * favorites = [SamLibAgent.settings() get: @"favorites"];
    return favorites.nonEmpty;
}

- (SectionNumber) sectionMap: (NSInteger) section
{
    if (!self.hasFavorites)
        section += 1;
    return section;
}

- (void) prepareData
{
    SamLibModel *model = [SamLibModel shared];
    
    if (_version != model.version ||
        self.authors == nil ||
        self.content == nil ||
        self.ignored == nil) {
        
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
        BOOL hasChangedSize = NO;
        for (SamLibText *text in author.texts)
            if (text.changedSize) {
                hasChangedSize = YES;
                [ma push:text];
            }
        author.hasChangedSize = hasChangedSize;
    }
    return ma;
}

- (void) goAddAuthor
{
    if (!self.addAuthorViewController) {
        self.addAuthorViewController = [[NewAuthorViewController alloc] initWithNibName:@"NewAuthorViewController" 
                                                                                 bundle:nil];
        self.addAuthorViewController.delegate = self;
    }
    
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:self.addAuthorViewController];
    
    [self presentViewController:navigationController 
                       animated:YES 
                     completion:NULL];
}

- (void) addNewAuthor: (SamLibAuthor *) author
{
    DDLogInfo(@"add author %@", author.path);
    
    [[SamLibModel shared] addAuthor:author]; 
    [self prepareData];    
}

- (void) goSettings
{
}

#pragma mark - refresh 

- (void) goStop
{
    SamLibAgent.cancelAll();
    [self.pullToRefreshView finishLoading];
    self.navigationItem.rightBarButtonItem = self.addButton;    
    self.content = [self mkContent];  
    [self.tableView reloadData];     
}

- (void) refresh
{           
    __block NSInteger count = self.authors.count;
    __block NSInteger reloaded = 0; 
    __block NSMutableArray * errors = nil;
        
    self.navigationItem.rightBarButtonItem = self.stopButton;
    [self.pullToRefreshView startLoading];

    for (SamLibAuthor *author in self.authors) {
        
        [author update:^(SamLibAuthor *author, SamLibStatus status, NSString *error) {
            
            if (status != SamLibStatusNotModifed)                
                ++reloaded;               
            
            if (status == SamLibStatusFailure) {
                
                if (!errors)
                    errors = [[NSMutableArray alloc] init];

                if (![errors containsObject:error])
                    [errors push: error];
                
                author.lastError = error;
                
            } else {
                author.lastError = nil;                
            }
            
            if (--count == 0) {
                
                [self.pullToRefreshView finishLoading];
                self.navigationItem.rightBarButtonItem = self.addButton;                
                
                if (reloaded > 0) {
                    
                    self.content = [self mkContent];  
                    [self.tableView reloadData];    
                }
                                
                if (errors.nonEmpty) {

                    //[[AppDelegate shared] errorNoticeInView:self.view 
                    //                                  title:locString(@"Reload failure") 
                    //                                message:[errors mkString: @"\n"]];
                    [self performSelector:@selector(showNoticeAboutReloadResult:) 
                               withObject:[errors mkString: @"\n"] 
                               afterDelay:1.0];
                    
                } else if (reloaded > 0) {

                    //[[AppDelegate shared] successNoticeInView:self.view 
                    //                                    title:locString(@"Reload success")];
                    
                    [self performSelector:@selector(showNoticeAboutReloadResult:) 
                               withObject:nil
                               afterDelay:1.0];

                }
                 
                
                errors = nil;
            }
        }];
    } 
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
    NSInteger sections = 1;
    if (self.hasFavorites)
        sections += 1;
    if (self.ignored.nonEmpty)
        sections += 1;        
    return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{   
    section = [self sectionMap:section];
    
    if (section == AuthorSectionNumber)
        return locString(@"Authors");
    
    else if (section == IgnoredSectionNumber)
        return locString(@"Ignored");
    
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    section = [self sectionMap:section];
    
    if (section == FavoritesSectionNumber)
        return 1;
    
    else if (section == AuthorSectionNumber)
        return self.content.count;
    
    else if (section == IgnoredSectionNumber)
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
    NSInteger section = [self sectionMap:indexPath.section];

    if (section == FavoritesSectionNumber) {
        
        UITableViewCell *cell = [self mkMainCell];
        cell.textLabel.text = locString(@"Favorites");
        return cell;
    }
        
    if (section == AuthorSectionNumber) {        
        
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
            if (author.lastError.nonEmpty) {
                cell.imageView.image = [UIImage imageNamed:@"failure.png"];
            } else if (author.hasChangedSize) {
                cell.imageView.image = [UIImage imageNamed:@"success.png"];                
            }
            return cell;
        }
    } 
    
    if (section == IgnoredSectionNumber) {        
        
        UITableViewCell *cell = [self mkMainCell];
        SamLibAuthor *author = [self.ignored objectAtIndex:indexPath.row];    
        cell.textLabel.text = author.name.nonEmpty ? author.name : author.path;
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{  
     NSInteger section = [self sectionMap:indexPath.section];
    if (section == AuthorSectionNumber) {
        id obj = [self.content objectAtIndex:indexPath.row];         
        if ([obj isKindOfClass:[SamLibText class]]) {         
            return systemFont14.lineHeight + 16;
        }        
    }    
    return self.tableView.rowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [self sectionMap:indexPath.section];
    if (section == AuthorSectionNumber) {
        id obj = [self.content objectAtIndex:indexPath.row];         
        if ([obj isKindOfClass:[SamLibText class]]) {         
            return 1;
        }        
    }    
    return 0;
}

@end
