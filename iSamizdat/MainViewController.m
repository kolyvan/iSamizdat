//
//  AuthorsViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 28.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
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
#import "AuthorViewController.h"
#import "TextViewController.h"
#import "FavoritesViewController.h"
#import "VotedViewController.h"
#import "UserViewController.h"
#import "SearchAuthorViewController.h"
#import "SettingsViewController.h"
#import "UIFont+Kolyvan.h"
#import "UIColor+Kolyvan.h"
#import "DDLog.h"

extern int ddLogLevel;

typedef enum {
    
    FavoritesSectionNumber  = 0,
    AuthorSectionNumber     = 1,
    IgnoredSectionNumber    = 2,    
    
} SectionNumber;

@interface MainViewController () {
    NSInteger _modelVersion;
    BOOL _tableLoaded;
    NSInteger _favoritesCount;
    NSInteger _votedCount;
}

@property (nonatomic, strong) NSArray *content;
@property (nonatomic, strong) NSArray *ignored;
@property (nonatomic, strong) NSArray *authors;
@property (nonatomic, strong) UIBarButtonItem *addButton;
@property (nonatomic, strong) AuthorViewController* authorViewController;
@property (nonatomic, strong) TextViewController* textViewController;
@property (nonatomic, strong) FavoritesViewController* favoritesViewController;
//@property (nonatomic, strong) UserViewController *userViewController;
@property (nonatomic, strong) SettingsViewController *settingsViewController;
@property (nonatomic, strong) VotedViewController* votedViewController;
@property (nonatomic, strong) SearchAuthorViewController *searchAuthorViewController;

@end

@implementation MainViewController

@synthesize content;
@synthesize ignored;
@synthesize authors;
@synthesize addButton;
@synthesize authorViewController;
@synthesize textViewController;
@synthesize favoritesViewController;
@synthesize settingsViewController;
@synthesize votedViewController;
@synthesize searchAuthorViewController;

- (id) init
{
    return [self initWithNibName:@"MainViewController" bundle:nil];
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
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back.png"]
                                                                   style:UIBarButtonItemStylePlain                                                                                           target:nil                                                                                            action:nil];

    
    self.navigationItem.backBarButtonItem = backButton;
    self.navigationItem.leftBarButtonItem = settingsButton;    
    self.navigationItem.rightBarButtonItem = self.addButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(samLibAuthorIgnoredChanged:)
                                                 name:@"SamLibAuthorIgnoredChanged" 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(samLibAuthorHasChangedSize:)
                                                 name:@"SamLibAuthorHasChangedSize" 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(samLibTextChanged:)
                                                 name:@"samLibTextChanged" 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(samLibTextChanged:)
                                                 name:@"samLibTextChanged" 
                                               object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.content = nil;
    self.ignored = nil;
    self.authors = nil;
    
    self.navigationItem.backBarButtonItem = nil;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    self.addButton = nil;
    self.textViewController = nil;
    self.favoritesViewController = nil;
    self.settingsViewController = nil;
    self.votedViewController = nil;
    self.searchAuthorViewController = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self prepareData];    
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];     

    self.authorViewController = nil;
    self.textViewController = nil;
    self.favoritesViewController = nil;    
    self.settingsViewController = nil;
    self.votedViewController = nil;    
    self.searchAuthorViewController = nil;    
}

#pragma mark - private functions

- (BOOL) hasFavorites
{
    return _favoritesCount > 0;
}

- (BOOL) hasVoted
{
    return _votedCount > 0;
}

- (SectionNumber) sectionMap: (NSInteger) section
{
    if (!self.hasFavorites && !self.hasVoted)
        section += 1;
    return section;
}

- (void) prepareData
{
    SamLibModel *model = [SamLibModel shared];
    
    if (_modelVersion != model.version ||
        self.authors == nil ||
        self.content == nil ||
        self.ignored == nil) {
        
        DDLogInfo(@"%@ prepareData", [self class]);
        
        _modelVersion = model.version;
        
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
    _favoritesCount = 0;
    _votedCount = 0;
    
    NSMutableArray * ma = [NSMutableArray array];            
    for (SamLibAuthor *author in self.authors) {            
        [ma push:author];            
        for (SamLibText *text in author.texts) {
            if (text.changedSize)
                [ma push:text];
            if (text.favorited)
                ++_favoritesCount;
            if (text.myVote != 0)
                ++_votedCount;
        }
    }
    return ma;
}

- (void) goAddAuthor
{    
    if (!self.searchAuthorViewController) {
        self.searchAuthorViewController = [[SearchAuthorViewController alloc] init];
        self.searchAuthorViewController.delegate = self;
        
    }
    
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:self.searchAuthorViewController];
    
    [self presentViewController:navigationController 
                       animated:YES 
                     completion:NULL];
}

- (void) searchAuthorResult: (SamLibAuthor *) author
{
    if (!self.authorViewController) {
        self.authorViewController = [[AuthorViewController alloc] init];
    }
    self.authorViewController.author = author;
    [self.navigationController pushViewController:self.authorViewController 
                                         animated:YES];
}

- (void) goSettings
{      
    if (!self.settingsViewController) {
        self.settingsViewController = [[SettingsViewController alloc] init];        
    }
    
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:self.settingsViewController];

    
    [self presentViewController:navigationController 
                       animated:YES 
                     completion:NULL];
    
    //[self.navigationController pushViewController:self.userViewController animated:YES];     
}

- (void) samLibAuthorIgnoredChanged:(NSNotification *)notification
{
    self.ignored = nil;
}

- (void) samLibAuthorHasChangedSize:(NSNotification *)notification
{
    self.content = nil;
}

- (void) samLibTextChanged:(NSNotification *)notification
{
    self.content = nil;
}

#pragma mark - refresh 

- (void) goStop
{
    [super goStop];
    
    self.content = [self mkContent];  
    [self.tableView reloadData];     
}

- (void) refresh: (void(^)(SamLibStatus status, NSString *error)) block
{
    __block NSInteger count = self.authors.count;
    __block NSInteger reloaded = 0; 
    __block NSMutableArray * errors = nil;
    
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
                
                if (reloaded > 0) {
                    status = SamLibStatusSuccess;   
                    self.content = [self mkContent];   
                }
                
                NSString *message = nil;
                if (errors.nonEmpty) {
                    
                    status = SamLibStatusFailure;
                    message = [errors mkString: @"\n"];
                    errors = nil; 
                }
                
                block(status, message);
            }
        }];
    }
}
 
- (NSDate *) lastUpdateDate
{
    NSDate *date = nil;
    if (self.authors.nonEmpty) {
        date = [self.authors fold:nil with:^id(id acc, id elem) {
            NSDate *l = acc, *r = ((SamLibAuthor *)elem).timestamp;
            return [r laterDate: l];
        }];
    }
    return date;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sections = 1;
    if (self.hasFavorites || self.hasVoted)
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
        return (self.hasFavorites ? 1 : 0) + (self.hasVoted ? 1 : 0);
    
    else if (section == AuthorSectionNumber)
        return self.content.count;
    
    else if (section == IgnoredSectionNumber)
        return self.ignored.count;

    return 0;
}

- (UITableViewCell *) mkMainCell
{
    UITableViewCell * cell = [self mkCell:@"MainCell" withStyle:UITableViewCellStyleDefault];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;    
    return cell;
}

- (UITableViewCell *) mkTextCell
{
    static NSString *CellIdentifier = @"TextCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.font = [UIFont systemFont14];
        cell.textLabel.font = [UIFont systemFont14];        
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [self sectionMap:indexPath.section];

    if (section == FavoritesSectionNumber) {
        
        UITableViewCell *cell = [self mkMainCell];
        
        if (indexPath.row == 0 && self.hasFavorites)        
            cell.textLabel.text = KxUtils.format(@"%@ (%ld)", locString(@"Favorites"), _favoritesCount);
        else
            cell.textLabel.text = KxUtils.format(@"%@ (%ld)", locString(@"Voted"), _votedCount);
        
        return cell;
    }
        
    if (section == AuthorSectionNumber) {        
        
        id obj = [self.content objectAtIndex:indexPath.row]; 
        
        if ([obj isKindOfClass:[SamLibText class]]) {
            
            UITableViewCell *cell = [self mkTextCell];
            SamLibText *text = obj;
            cell.detailTextLabel.text = KxUtils.format(@"%+ldk", text.deltaSize);
            cell.textLabel.text = text.title;
            cell.textLabel.textColor = [UIColor secondaryTextColor];  
            return cell;            
        }
        
        if ([obj isKindOfClass:[SamLibAuthor class]]) {
            
            UITableViewCell *cell = [self mkMainCell];
            SamLibAuthor *author = obj;
            cell.textLabel.text = author.name.nonEmpty ? author.name : author.path;
            cell.textLabel.textColor = [UIColor darkTextColor];                        
            if (author.lastError.nonEmpty) {
                cell.imageView.image = [UIImage imageNamed:@"failure.png"];
            } else if (author.hasChangedSize) {
                cell.imageView.image = [UIImage imageNamed:@"success.png"];                
            } else {
                cell.imageView.image = nil;
            }
            return cell;
        }
    } 
    
    if (section == IgnoredSectionNumber) {        
        
        UITableViewCell *cell = [self mkMainCell];
        SamLibAuthor *author = [self.ignored objectAtIndex:indexPath.row];    
        cell.textLabel.text = author.name.nonEmpty ? author.name : author.path;
        cell.textLabel.textColor = [UIColor grayColor];
        cell.imageView.image = nil;        
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
            return [UIFont systemFont14].lineHeight + 16;
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [self sectionMap:indexPath.section];
    
    if (section == FavoritesSectionNumber) {
        
        if (indexPath.row == 0 && self.hasFavorites) {
            
            if (!self.favoritesViewController) {
                self.favoritesViewController = [[FavoritesViewController alloc] init];        
            }
            [self.navigationController pushViewController:self.favoritesViewController 
                                                 animated:YES];
            
        } else {
        
            if (!self.votedViewController) {
                self.votedViewController = [[VotedViewController alloc] init];        
            }
            [self.navigationController pushViewController:self.votedViewController 
                                                 animated:YES];
            
        }
        
    } else if (section == AuthorSectionNumber) {
        
        id obj = [self.content objectAtIndex:indexPath.row];         
        if ([obj isKindOfClass:[SamLibAuthor class]]) {         
            
            if (!self.authorViewController) {
                self.authorViewController = [[AuthorViewController alloc] init];
            }
            self.authorViewController.author = obj;
            [self.navigationController pushViewController:self.authorViewController 
                                                 animated:YES];
            
        } else if ([obj isKindOfClass:[SamLibText class]]) {
            
            if (!self.textViewController) {
                self.textViewController = [[TextViewController alloc] init];
            }
            self.textViewController.text = obj;
            [self.navigationController pushViewController:self.textViewController 
                                                 animated:YES];
        }
        
    } else if (section == IgnoredSectionNumber) {
        
        SamLibAuthor *author = [self.ignored objectAtIndex:indexPath.row];         
        
        if (!self.authorViewController) {
            self.authorViewController = [[AuthorViewController alloc] init];
        }
        self.authorViewController.author = author;
        [self.navigationController pushViewController:self.authorViewController 
                                                 animated:YES];

    } 
}

@end
