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
#import "UIFont+Kolyvan.h"
#import "UIColor+Kolyvan.h"
#import "DDLog.h"

extern int ddLogLevel;

typedef enum {

    AuthorSectionNumber     = 0,
    IgnoredSectionNumber    = 1,    
    
} SectionNumber;

@interface MainViewController () {
    NSInteger _modelVersion;
    BOOL _tableLoaded;
}

@property (nonatomic, strong) NSArray *content;
@property (nonatomic, strong) NSArray *ignored;
@property (nonatomic, strong) NSArray *authors;
@property (nonatomic, strong) AuthorViewController* authorViewController;
@property (nonatomic, strong) TextViewController* textViewController;

@end

@implementation MainViewController

@synthesize content;
@synthesize ignored;
@synthesize authors;
@synthesize authorViewController;
@synthesize textViewController;

- (id) init
{
    self = [super initWithNibName:@"MainViewController" bundle:nil];
    if (self) {
        self.title = locString(@"Samizdat");
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemFeatured tag: 0];                
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
   
    //self.navigationController.navigationBarHidden = YES;
       
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
    self.authorViewController = nil;
    self.textViewController = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self prepareData];        
    //[self.navigationController setNavigationBarHidden:YES animated:YES];    
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];     

    self.authorViewController = nil;
    self.textViewController = nil;
}

#pragma mark - private functions

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
    
    NSMutableArray * ma = [NSMutableArray array];            
    for (SamLibAuthor *author in self.authors) {            
        [ma push:author];            
        for (SamLibText *text in author.texts) {
            if (text.changedSize || (text.isNew && text.flagNew != nil))
                [ma push:text];           
        }
    }
    return ma;
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
    if (self.ignored.nonEmpty)
        sections += 1;        
    return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{           
    if (section == IgnoredSectionNumber)
        return locString(@"Ignored");
    
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    if (section == AuthorSectionNumber)
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
    NSInteger section = indexPath.section;
           
    if (section == AuthorSectionNumber) {        
        
        id obj = [self.content objectAtIndex:indexPath.row]; 
        
        if ([obj isKindOfClass:[SamLibText class]]) {
            
            UITableViewCell *cell = [self mkTextCell];
            SamLibText *text = obj;
            if (text.changedSize)
                cell.detailTextLabel.text = KxUtils.format(@"%+ldk", text.deltaSize);
            else
                cell.detailTextLabel.text = locString(@"new");
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
     NSInteger section = indexPath.section;
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
    NSInteger section = indexPath.section;
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
    NSInteger section = indexPath.section;
    
   if (section == AuthorSectionNumber) {
        
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
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    //[self.navigationController setNavigationBarHidden: NO animated:YES];
}

@end
