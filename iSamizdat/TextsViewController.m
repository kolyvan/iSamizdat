//
//  TextsViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 16.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "TextsViewController.h"
#import "KxMacros.h"
#import "NSArray+Kolyvan.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"

@interface TextsViewController () {
    NSMutableArray *_texts;
}
@end

@implementation TextsViewController
@synthesize texts = _texts;
@synthesize tableView = _tableView;
@synthesize textContainerController = _textContainerController;

- (void) loadView
{
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero 
                                              style:UITableViewStylePlain];
    
    self.view = _tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshView];   
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.textContainerController = nil;
    _tableView.delegate = nil;
    _tableView.dataSource = nil;    
    _texts = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
    self.textContainerController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSArray *) prepareData
{
    NSAssert(false, @"abstract call");
    return nil;
}

- (NSInteger) textContainerSelected
{
    return TextInfoViewSelected;
}

- (void) refreshView
{
    _texts = [[self prepareData] mutableCopy];
     [self.tableView reloadData];
}

- (BOOL) canRemoveText: (SamLibText *) text
{
    return NO;
}

- (void) handleRemoveText: (SamLibText *) text
{
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{   
    return _texts.count;
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
    UITableViewCell *cell; 
    cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleSubtitle];    
      
    SamLibText *text = [_texts objectAtIndex:indexPath.row]; 
        
    cell.textLabel.text = text.title;
    cell.detailTextLabel.text = text.author.name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = text.image;    
        
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SamLibText *text = [_texts objectAtIndex:indexPath.row];     
    if (!self.textContainerController)
        self.textContainerController = [[TextContainerController alloc] init];    
    self.textContainerController.text = text;
    self.textContainerController.selected = self.textContainerSelected;    
    [self.navigationController pushViewController:self.textContainerController 
                                         animated:YES];
    
    //[self.tableView deselectRowAtIndexPath:indexPath animated:YES];    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView 
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SamLibText *text = [_texts objectAtIndex:indexPath.row];        
    return [self canRemoveText:text] ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;    
}

- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath
{ 
    SamLibText *text = [_texts objectAtIndex:indexPath.row];        
    [self handleRemoveText:text];        
    [_texts removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                     withRowAnimation:UITableViewRowAnimationAutomatic];       
}

@end
