//
//  TextGroupViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 15.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "TextGroupViewController.h"
#import "NSArray+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"
#import "UIFont+Kolyvan.h"
#import "TextViewController.h"

@interface TextGroupViewController () {
    BOOL _needReload;
}
@property (readwrite, nonatomic, strong) TextViewController* textViewController;
@end

@implementation TextGroupViewController

@synthesize texts = _texts;
@synthesize textViewController;

- (void) setTexts:(NSArray *)texts
{
    if (![texts isEqualToArray: _texts]) {        
        _texts = texts;
        _needReload = YES;        
    }
}

- (id) init
{
    return [self initWithNibName:@"TextGroupViewController" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];    
}

- (void) viewWillAppear:(BOOL)animated 
{    
    [super viewWillAppear:animated];
    if (_needReload) {
        _needReload = NO;    
        SamLibText *text = _texts.first;
        self.title = text.groupEx;        
        [self.tableView reloadData];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.texts = nil;
    self.textViewController = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
    self.textViewController = nil; 
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                      reuseIdentifier:CellIdentifier];                
    }
    
    SamLibText *text = [_texts objectAtIndex:indexPath.row];    

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = text.title;
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.font = [UIFont boldSystemFont16];
    cell.imageView.image = text.image;        
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.textViewController) {
        self.textViewController = [[TextViewController alloc] init];
    }
    
    self.textViewController.text = [_texts objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:self.textViewController 
                                         animated:YES]; 

}

@end
