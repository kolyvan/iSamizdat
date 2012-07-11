//
//  SettingsViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 20.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "SettingsViewController.h"
#import "KxMacros.h"
#import "UserViewController.h"
#import "CacheViewController.h"
#import "SamLibModerator.h"
#import "DDLog.h"

extern int ddLogLevel;

enum {

    SettingsViewUserRow,
    SettingsViewCacheRow,
    SettingsViewFilterRow,    
    
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
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:locString(@"Settings")
                                                        image:[UIImage imageNamed:@"emblem-system"] 
                                                          tag:5];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //self.navigationController.navigationBarHidden = YES;    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.rightBarButtonItem = nil;
    self.userViewController = nil;
    self.cacheViewController = nil;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self.navigationController setNavigationBarHidden:YES animated:YES];
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

- (void) switchCellValueChanged: (UISwitch *) sender
{
    SamLibModerator *moderator = [SamLibModerator shared];
    
    SamLibBan *ban = [moderator findByName:@"censored"];
    if (ban) 
        ban.enabled = sender.on;
    else {
        
        SamLibBanRule *rule = [[SamLibBanRule alloc] initFromPattern:@"censored" 
                                                            category:SamLibBanCategoryText];        
        rule.option = SamLibBanRuleOptionLink;
        
        ban = [[SamLibBan alloc] initWithName:@"censored" 
                                        rules:[NSArray arrayWithObject:rule] 
                                    tolerance:1 
                                         path:@""];
        ban.enabled = YES;
        
        [moderator addBan:ban];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SamLibFilterSettingsChanged" object:nil];
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

- (UITableViewCell *) mkCell: (NSString *)cellIdentifier
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                      reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }    
    return cell;
}

- (UITableViewCell *) mkSwitchCell: (NSString *)cellIdentifier
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                      reuseIdentifier:cellIdentifier];
        UISwitch * button = [[UISwitch alloc] initWithFrame:CGRectZero]; 
        [button addTarget:self 
                   action:@selector(switchCellValueChanged:) 
         forControlEvents:UIControlEventValueChanged]; 
        cell.accessoryView = button;    
    }  
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
  
    if (SettingsViewUserRow == indexPath.row) {
        
        cell = [self mkCell: @"Cell"];
        cell.textLabel.text = locString(@"User Info");
        
    } else if (SettingsViewCacheRow == indexPath.row) {

        cell = [self mkCell: @"Cell"];        
        cell.textLabel.text = locString(@"Cache Settings");

    } else if (SettingsViewFilterRow == indexPath.row) {
        
        cell = [self mkSwitchCell: @"SwitchCell"];        
        UISwitch *button = (UISwitch *)cell.accessoryView;        
        cell.textLabel.text = locString(@"Filter bad language");
        
        SamLibBan *ban = [[SamLibModerator shared] findByName:@"censored"];        
        button.on = ban.enabled;        
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
    
    //[self.navigationController setNavigationBarHidden:NO animated:YES];    
}

@end
