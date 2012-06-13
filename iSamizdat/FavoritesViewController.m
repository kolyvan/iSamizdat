//
//  FavoritesViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "FavoritesViewController.h"
#import "KxMacros.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "SamLibAgent.h"
#import "SamLibModel.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"
#import "SamLibAuthor.h"
#import "TextViewController.h"

@interface FavoritesViewController () {
    NSArray *_texts;
}
@property (nonatomic, strong) TextViewController* textViewController;
@end

@implementation FavoritesViewController

@synthesize textViewController;

- (id) init
{
    self =  [self initWithNibName:@"FavoritesViewController" bundle:nil];
    if (self) {
        self.title = locString(@"Favorites");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self prepareData];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.textViewController = nil;
    _texts = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
    self.textViewController = nil;    
}

#pragma mark - private

- (void) prepareData
{
    _texts = nil;
        
    NSMutableArray * ma = [NSMutableArray array];
        
    for (SamLibAuthor *author in [SamLibModel shared].authors) {
        
        for (SamLibText *text in author.texts) {
            
            if (text.favorited) {
                
                [text commentsObject:YES]; // force to load comments from disk
                [ma push:text];
            }
        }
    }
    
    if (ma.nonEmpty)
        _texts = [ma copy];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _texts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    SamLibText *text = [_texts objectAtIndex:indexPath.row]; 
    UITableViewCell *cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleSubtitle];    
    cell.textLabel.text = text.title;
    cell.detailTextLabel.text = text.author.name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = text.image;        
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{            
    if (!self.textViewController) {
        self.textViewController = [[TextViewController alloc] init];
    }
    SamLibText *text = [_texts objectAtIndex:indexPath.row];    
    self.textViewController.text = text;
    [self.navigationController pushViewController:self.textViewController 
                                                 animated:YES];
}


@end
