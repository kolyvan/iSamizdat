//
//  AuthorInfoViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 15.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "AuthorInfoViewController.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "SamLibAuthor+IOS.h"
#import "SHK.h"

enum {
    RowName,
    RowRating,    
    RowStatus,    
    RowUpdated,
    RowSize,
    RowVisitors,
    RowIgnore,    
    RowRemove,        
};

@interface AuthorInfoViewController () {
    BOOL _needReload;
}
@end

@implementation AuthorInfoViewController

@synthesize author = _author;

- (void) setAuthor:(SamLibAuthor *)author
{
    if (author != _author) {
        _needReload = YES;
        _author = author;
    }
}

- (id) init
{
    return [self initWithNibName:@"AuthorInfoViewController" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *goButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                                              target:self 
                                                                              action:@selector(goShare)];
    self.navigationItem.rightBarButtonItem = goButton;    
    
    self.title = locString(@"Info");
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_needReload) {
        _needReload = NO;
        [self.tableView reloadData];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.rightBarButtonItem = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) goShare
{   
    SHKItem *item = [SHKItem URL:[NSURL URLWithString: [@"http://" stringByAppendingString: _author.url]] 
                           title:KxUtils.format(@"%@. %@.", _author.name, _author.title) 
                     contentType:(SHKURLContentTypeWebpage)];
    SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    [SHK setRootViewController:self];
    [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem 
                              animated:YES]; 
}

- (void) goDelete
{
    UIActionSheet *actionSheet;
    actionSheet = [[UIActionSheet alloc] initWithTitle:locString(@"Are you sure?")
                                                       delegate:self
                                              cancelButtonTitle:locString(@"Cancel") 
                                         destructiveButtonTitle:locString(@"Delete") 
                                              otherButtonTitles:nil];

    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        
        [[SamLibModel shared] deleteAuthor:_author];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void) goIgnore: (id) sender
{
    UISwitch *button = sender;    
    _author.ignored = button.on;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SamLibAuthorIgnoredChanged" object:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 8;
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
      
    NSInteger row = indexPath.row;
    
    if (RowName == row) {
        
        cell = [self mkCell: @"NameCell" withStyle:UITableViewCellStyleSubtitle];        
        cell.textLabel.text = _author.name;
        cell.detailTextLabel.text = _author.title;  
        
    } else if (RowRating == row) {
        
        cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleValue1];        
        cell.textLabel.text = locString(@"Rating");
        cell.detailTextLabel.text = _author.rating;
        
    } else if (RowUpdated == row) {
        
        cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleValue1];        
        cell.textLabel.text = locString(@"Updated");
        cell.detailTextLabel.text = _author.updated;
        
    } else if (RowSize == row) {     

        cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleValue1];                
        cell.textLabel.text = locString(@"Amount");
        cell.detailTextLabel.text = _author.size;
        
    } else if (RowVisitors == row) {    
        
        cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleValue1];                
        cell.textLabel.text = locString(@"Visitors");
        cell.detailTextLabel.text = _author.visitors;
        
    } else if (RowIgnore == row) {
        
        static NSString *CellIdentifier = @"IgnoreCell";        
        cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];    
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                          reuseIdentifier:CellIdentifier];  
            
            UISwitch * button = [[UISwitch alloc] initWithFrame:CGRectZero]; 
            
            [button addTarget:self 
                       action:@selector(goIgnore:) 
             forControlEvents:UIControlEventValueChanged ];
            cell.accessoryView = button;
            cell.textLabel.text = locString(@"Ignore");               
        }
        
        ((UISwitch *)cell.accessoryView).on = _author.ignored;
        
    } else if (RowRemove == row) {        
        
        static NSString *CellIdentifier = @"RemoveCell";
        cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];    
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                          reuseIdentifier:CellIdentifier];  
            
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(0, 0, 24, 24);                    
            [button addTarget:self 
                       action:@selector(goDelete) 
             forControlEvents:UIControlEventTouchUpInside];                    
            [button setBackgroundImage:[UIImage imageNamed:@"delete.png"]
                               forState:UIControlStateNormal];
            cell.accessoryView = button;  
            //cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;            
            cell.textLabel.text = locString(@"Delete");                
            //cell.textLabel.textColor = [UIColor redColor];
        }
    } else if (RowStatus == row) {    
        
        cell = [self mkCell: @"StatusCell" withStyle:UITableViewCellStyleDefault];                
        
        if (_author.lastError.nonEmpty) {
            
            cell.imageView.image = [UIImage imageNamed:@"failure.png"];
            cell.textLabel.text = _author.lastError;
            cell.textLabel.textColor = [UIColor redColor];
            
        } else if (_author.hasChangedSize) {
            
            cell.imageView.image = [UIImage imageNamed:@"success.png"];                
            cell.textLabel.text = locString(@"Updated");
            cell.textLabel.textColor = [UIColor blueColor];
            
        } else {
            cell.imageView.image = nil;
            cell.textLabel.text = locString(@"No updates");
        }
    }     
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
