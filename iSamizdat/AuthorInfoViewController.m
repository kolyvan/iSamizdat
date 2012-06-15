//
//  AuthorInfoViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 15.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "AuthorInfoViewController.h"
#import "KxMacros.h"
#import "SamLibAuthor.h"

enum {
    RowName,
    RowRating,    
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
    
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                                                target:self 
                                                                                action:@selector(goSafari)];
    self.navigationItem.rightBarButtonItem = infoButton;    
    
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

- (void) goSafari
{    
    NSURL *url = [NSURL URLWithString: [@"http://" stringByAppendingString: _author.url]];
    [UIApplication.sharedApplication openURL: url];                     
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 7;
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
            cell.accessoryView = button;
            cell.textLabel.text = locString(@"Ignore");               
        }
        
    } else if (RowRemove == row) {        
        
        static NSString *CellIdentifier = @"RemoveCell";
        cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];    
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                          reuseIdentifier:CellIdentifier];  
            
            /*
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(0, 0, 100, 30);        
            [button setTitle:@"Remove" forState:UIControlStateNormal];
            [button addTarget:self 
                       action:@selector(goRemove) 
             forControlEvents:UIControlEventTouchUpInside];                    
            [button setBackgroundImage:[UIImage imageNamed:@"button_red.png"]
                               forState:UIControlStateNormal];
            cell.accessoryView = button;        
            */  
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;            
            cell.textLabel.text = locString(@"Delete");                
            //cell.textLabel.textColor = [UIColor redColor];
        }
    }    
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
