//
//  AuthorViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 29.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "AuthorViewController.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "TextViewController.h"

@interface AuthorViewController () {
    BOOL _needReload;
    id _version;
    NSArray *_sections;
}
@property (nonatomic, strong) TextViewController *textViewController;

@end

@implementation AuthorViewController

@synthesize author = _author;
@synthesize textViewController;

- (void) setAuthor:(SamLibAuthor *)author 
{
    if (author != _author || 
        ![author.version isEqual:_version]) {        
        
        _version = author.version;
        _author = author;
        _needReload = YES;
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
                                                                   style: UIBarButtonItemStylePlain 
                                                                  target:nil
                                                                  action:nil];
    
    self.navigationItem.backBarButtonItem = backButton;
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
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSArray *section = [_sections objectAtIndex:indexPath.section];    
    id obj = [section objectAtIndex:indexPath.row]; 
    
    if ([obj isKindOfClass:[SamLibText class]]) {
        
        SamLibText* text = obj;
        cell.textLabel.text = text.title;  
        
    } else if ([obj isKindOfClass:[NSString class]]) {
        
        cell.textLabel.text = obj;  
        
    }
    
    return cell;
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
