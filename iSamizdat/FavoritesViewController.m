//
//  FavoritesViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 31.05.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
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
#import "TextContainerController.h"


@interface FavoritesViewController () {
    NSMutableArray *_texts;
}
@property (nonatomic, strong) TextContainerController *textContainerController;
@end

@implementation FavoritesViewController

@synthesize textContainerController;

- (id) init
{
    self =  [self initWithNibName:@"FavoritesViewController" bundle:nil];
    if (self) {
        self.title = locString(@"Favorites");        
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemBookmarks tag: 1]; 
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //self.navigationController.navigationBarHidden = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self.navigationController setNavigationBarHidden:YES animated:YES];    
    [self prepareData];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.textContainerController = nil;
    _texts = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
    self.textContainerController = nil;    
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
    
    _texts = ma;
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
    SamLibText *text = [_texts objectAtIndex:indexPath.row];    
    
    if (!self.textContainerController)
        self.textContainerController = [[TextContainerController alloc] init];    
    self.textContainerController.text = text;
    self.textContainerController.selectedIndex = TextInfoViewSelected;

    [self.navigationController pushViewController:self.textContainerController 
                                         animated:YES];
    //[self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    SamLibText *text = [_texts objectAtIndex:indexPath.row];      
    text.favorited = NO;        
    [_texts removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                     withRowAnimation:UITableViewRowAnimationAutomatic];        
    
}

@end
