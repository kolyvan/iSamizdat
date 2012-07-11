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
#import "TextContainerController.h"
#import "TextGroupViewController.h"
#import "AuthorInfoViewController.h"
#import "AppDelegate.h"
#import "UIFont+Kolyvan.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface AuthorViewController () {
    BOOL _needReload;
    id _version;
    NSArray * _textVersions;
    NSArray *_sections;
}
@property (nonatomic, strong) TextContainerController *textContainerController;
@property (nonatomic, strong) TextGroupViewController * textGroupViewController;
@property (nonatomic, strong) AuthorInfoViewController* authorInfoViewController;
@end

@implementation AuthorViewController

@synthesize author = _author;
@synthesize textContainerController;
@synthesize textGroupViewController;
@synthesize authorInfoViewController;

- (void) setAuthor:(SamLibAuthor *)author 
{
    if (author != _author || 
        ![author.version isEqual:_version]) {        
        
        _textVersions = nil;
        _version = author.version;
        _author = author;
        _needReload = YES;
    }
}

- (id) init
{
    self = [self initWithNibName:@"AuthorViewController" bundle:nil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
       
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize 
                                                                                target:self 
                                                                               action:@selector(goInfo)];            

    self.navigationItem.rightBarButtonItem = infoButton;        
    
    UILabel *label = [[UILabel alloc] init];    
    label.numberOfLines = 0;
    label.font = [UIFont boldSystemFont16];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    //label.shadowColor = [UIColor blackColor];
    //label.shadowOffset = CGSizeMake(0,-1);
    self.navigationItem.titleView = label;     
    
}

- (void) viewWillAppear:(BOOL)animated 
{   
    [super viewWillAppear:animated];
        
    if (_needReload) {
        _needReload = NO;
        
        self.title = _author.name;
                
        CGRect rc;
        UILabel *label = (UILabel *)self.navigationItem.titleView;
        rc.size = self.navigationController.navigationBar.bounds.size;            
        rc.size = [_author.name sizeWithFont:[UIFont boldSystemFont16] 
                      constrainedToSize:CGSizeMake(rc.size.width - 110, rc.size.height - 4) 
                          lineBreakMode:UILineBreakModeTailTruncation];
        label.bounds = rc;
        label.text = _author.name;  
                
        [self prepareData];
        [self.tableView reloadData];
        
    } else {
    
        NSArray *a = [_author.texts map:^id(id elem) {
            return ((SamLibText *)elem).version;
        }];
        
        if (![_textVersions isEqualToArray:a]) {
            
            _textVersions = a;
            // todo: reload a text's row with changed version only?
            [self.tableView reloadData];
        }
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!_author.lastModified && !_author.digest)
        [self forceRefresh];
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.navigationItem.backBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.titleView = nil;
    self.textContainerController = nil;
    self.textGroupViewController = nil;
    self.authorInfoViewController = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
    self.textContainerController = nil;
    self.textGroupViewController = nil;
    self.authorInfoViewController = nil;    
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
            
            if (![ma containsObject:text.group])
                [ma push: text.group];     
            
        } else {
            
            [ma push: text];        
        }
    }
    
    _sections = sections.allValues;
    
    _textVersions = [_author.texts map:^id(id elem) {
        return ((SamLibText *)elem).version;
    }];
}

- (void) goSafari
{    
    NSURL *url = [NSURL URLWithString: [@"http://" stringByAppendingString: _author.url]];
    [UIApplication.sharedApplication openURL: url];                     
}

- (void) goInfo
{
    if (!self.authorInfoViewController) {
        self.authorInfoViewController = [[AuthorInfoViewController alloc] init];
    }
    
    self.authorInfoViewController.author = _author;
    [self.navigationController pushViewController:self.authorInfoViewController 
                                         animated:YES]; 
}

- (void) refresh: (void(^)(SamLibStatus status, NSString *error)) block
{   
     [_author update:^(SamLibAuthor *author, SamLibStatus status, NSString *error) {
        
         NSString *message;
         
         if (status == SamLibStatusFailure) {            
             
             author.lastError = error;
             message = error;
             
         } else {
             author.lastError = nil;
         }
         
         if (status == SamLibStatusSuccess && 
             author.hasChangedSize) {
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"SamLibAuthorHasChangedSize" object:nil];
             
             message = locString(@"Update is available");
         }
         
         block(status, message);
     }];
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
        cell.textLabel.font = [UIFont boldSystemFont16];
        cell.imageView.image = text.image;        
        
        return cell;        
    } 
    
    if ([obj isKindOfClass:[NSString class]]) {
        
        NSString *groupName = obj;
        if (groupName.first == '@')
            groupName = groupName.tail;
        
        UITableViewCell *cell = [self mkCell: @"GroupCell" withStyle:UITableViewCellStyleDefault];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;        
        cell.textLabel.text = groupName;  
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

        if (!self.textContainerController) {
            self.textContainerController = [[TextContainerController alloc] init];
        }
        
        self.textContainerController.text = obj;
        self.textContainerController.selectedIndex = TextInfoViewSelected;
        [self.navigationController pushViewController:self.textContainerController 
                                             animated:YES]; 
        
    } else if ([obj isKindOfClass:[NSString class]]) {
               
        if (!self.textGroupViewController) {
            self.textGroupViewController = [[TextGroupViewController alloc] init];
        }
        
        NSString *groupName = obj;        
        NSArray *a = [_author.texts filter:^(id elem) {
            SamLibText * p = elem;
            return [p.group isEqualToString:groupName];
        }];
        
        self.textGroupViewController.texts = a;
        [self.navigationController pushViewController:self.textGroupViewController 
                                             animated:YES];         
    }
}

@end
