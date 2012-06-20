//
//  SettingsViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 20.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "SettingsViewController.h"
#import "KxMacros.h"
#import "UserViewController.h"
#import "CacheViewController.h"

enum {

    SettingsViewUserRow,
    SettingsViewCacheRow,
    
    SettingsViewNumberOfRows,
};

@interface SettingsViewController ()
@property (nonatomic, strong) UserViewController *userViewController;
@property (nonatomic, strong) CacheViewController *cacheViewController;
@end

@implementation SettingsViewController

@synthesize userViewController, cacheViewController;

- (id) init
{
    self = [self initWithNibName:@"SettingsViewController" bundle:nil];
    if (self) {
        self.title = locString(@"Settings");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back.png"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = backButton;    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.rightBarButtonItem = nil;
    self.userViewController = nil;
    self.cacheViewController = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning]; 
    self.userViewController = nil;
    self.cacheViewController = nil;    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) goBack
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return SettingsViewNumberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                      reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }    
  
    if (SettingsViewUserRow == indexPath.row) {
        
        cell.textLabel.text = locString(@"User info");
        
    } else if (SettingsViewCacheRow == indexPath.row) {

        cell.textLabel.text = locString(@"Cache settings");
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (SettingsViewUserRow == indexPath.row) {
        
        if (!self.userViewController) {
            self.userViewController = [[UserViewController alloc] init];        
        }
        [self.navigationController pushViewController:self.userViewController 
                                             animated:YES];          
        
    } else if (SettingsViewCacheRow == indexPath.row) {
        
        if (!self.cacheViewController) {
            self.cacheViewController = [[CacheViewController alloc] init];        
        }
        [self.navigationController pushViewController:self.cacheViewController 
                                             animated:YES]; 
    }
}

@end
