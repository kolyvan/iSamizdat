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
#import "NSArray+Kolyvan.h"
#import "UserViewController.h"
#import "CacheViewController.h"
#import "AboutViewController.h"
#import "SamLibAgent.h"
#import "SamLibModerator.h"
#import "SamLibComments.h"
//#import "SelectFontViewController.h"
#import "KxUtils.h"
#import "DDLog.h"

extern int ddLogLevel;

enum {
    
    SettingsViewSection0AboutRow,    
    SettingsViewSection0UserRow,
    SettingsViewSection0CacheRow,    
    
    SettingsViewSection0NumberOfRows,
};

enum {
    
    SettingsViewSection1FilterRow,   
    SettingsViewSection1MaxCommentsRow,       
    
    SettingsViewSection1NumberOfRows,    
};

enum {

    SettingsViewSection2TextZoom, 
    //SettingsViewSection2FontName,       
    //    SettingsViewSection2TextColor,     
    //    SettingsViewSection2Textbackground,         
    
    SettingsViewSection2NumberOfRows,    
};

#define SLIDER_COMMENTS 1
#define SLIDER_FONTSIZE 2

#define FIRST_PAGE_COMMENTS_NUMBER 10
#define NEXT_PAGE_COMMENTS_NUMBER  40
#define MIN_COMMENTS_PAGES 1
#define MAX_COMMENTS_PAGES 6

@interface SettingsViewController ()
@property (nonatomic, strong) UserViewController *userViewController;
@property (nonatomic, strong) CacheViewController *cacheViewController;
@property (nonatomic, strong) AboutViewController *aboutViewController;
//@property (nonatomic, strong) SelectFontViewController *selectFontViewController;
@end

@implementation SettingsViewController

@synthesize userViewController, cacheViewController, aboutViewController;

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
    self.aboutViewController = nil;
//    self.selectFontViewController = nil;
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
    self.aboutViewController = nil;  
//    self.selectFontViewController = nil;
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
}

- (void) sliderCellValueChanged: (UISlider *)slider
{   
    if (SLIDER_COMMENTS == slider.tag) {
        
        NSUInteger maxCount = ceil(slider.value - 1) * NEXT_PAGE_COMMENTS_NUMBER + FIRST_PAGE_COMMENTS_NUMBER;    
        [SamLibComments setMaxComments: maxCount];        
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:SettingsViewSection1MaxCommentsRow
                                                    inSection:1];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];        
        cell.textLabel.text = KxUtils.format(locString(@"Maximum (%d)"), maxCount);        
        
    } else if (SLIDER_FONTSIZE == slider.tag) {
        
        CGFloat zoom = (int)(slider.value * 10) * 0.1;                
        SamLibAgent.setSettingsFloat(@"text.zoom", zoom, 1.0); 
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SamLibTextSettingsChanged" object:nil];        
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:SettingsViewSection2TextZoom
                                                    inSection:2];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];        
        cell.textLabel.text = KxUtils.format(@"Zoom (%.1f)", zoom);                
    }
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: return SettingsViewSection0NumberOfRows;
        case 1: return SettingsViewSection1NumberOfRows;            
        case 2: return SettingsViewSection2NumberOfRows;                        
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return @"";
        case 1: return locString(@"Comments");
        case 2: return locString(@"Text");            
    }
    return @"";
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

- (UITableViewCell *) mkSliderCell: (NSString *)cellIdentifier
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                      reuseIdentifier:cellIdentifier];
        UISlider * slider = [[UISlider alloc] initWithFrame:CGRectMake(0,0, 120, 30)]; 
        [slider addTarget:self 
                   action:@selector(sliderCellValueChanged:) 
         forControlEvents:UIControlEventValueChanged]; 
        cell.accessoryView = slider;    
        //[slider sizeToFit];
    }  
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (0 == indexPath.section) {
        
        if (SettingsViewSection0UserRow == indexPath.row) {
            
            cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleDefault];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = locString(@"User Info");
            
        } else if (SettingsViewSection0CacheRow == indexPath.row) {
            
            cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleDefault]; 
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;            
            cell.textLabel.text = locString(@"Cache Settings");
            
        } else if (SettingsViewSection0AboutRow == indexPath.row) {
            
            cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleDefault]; 
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;            
            cell.textLabel.text = locString(@"About");
            
        } 
        
    } else if (1 == indexPath.section) {
        
        if (SettingsViewSection1FilterRow == indexPath.row) {
            
            cell = [self mkSwitchCell: @"SwitchCell"];        
            UISwitch *button = (UISwitch *)cell.accessoryView;        
            cell.textLabel.text = locString(@"Filter bad language");
            
            SamLibBan *ban = [[SamLibModerator shared] findByName:@"censored"];        
            button.on = ban.enabled;        
            
        } else if (SettingsViewSection1MaxCommentsRow == indexPath.row) {
            
            cell = [self mkSliderCell: @"SlideCell"];  
            
            NSInteger maxCount = [SamLibComments maxComments];
            
            cell.textLabel.text = KxUtils.format(locString(@"Maximum (%d)"), maxCount);        
            cell.selectionStyle = UITableViewCellSelectionStyleNone;            
            
            UISlider *slider = (UISlider *)cell.accessoryView;                    
            slider.continuous = NO;
            slider.maximumValue = MAX_COMMENTS_PAGES;
            slider.minimumValue = MIN_COMMENTS_PAGES;        
            slider.tag = SLIDER_COMMENTS;

            slider.value = (((CGFloat)maxCount - FIRST_PAGE_COMMENTS_NUMBER) / NEXT_PAGE_COMMENTS_NUMBER) + 1; 
        }
        
    } else if (2 == indexPath.section) {
        
        if (SettingsViewSection2TextZoom == indexPath.row) {
            
            //cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleValue1];             
            //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;  
            
            CGFloat zoom = SamLibAgent.settingsFloat(@"text.zoom", 1.0);
            
            cell = [self mkSliderCell:@"SlideCell"]; 
            cell.textLabel.text = KxUtils.format(locString(@"Zoom (%.1f)"), zoom);                
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UISlider *slider = (UISlider *)cell.accessoryView;  
            
            slider.continuous = NO;
            slider.maximumValue = 1.5;
            slider.minimumValue = 0.5;   
            slider.tag = SLIDER_FONTSIZE;
            slider.value = zoom;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (0 == indexPath.section) {
        
        if (SettingsViewSection0AboutRow == indexPath.row) {
            
            if (!self.aboutViewController) {
                self.aboutViewController = [[AboutViewController alloc] init];        
            }
            [self.navigationController pushViewController:self.aboutViewController 
                                                 animated:YES]; 
            
        } else if (SettingsViewSection0UserRow == indexPath.row) {
            
            if (!self.userViewController) {
                self.userViewController = [[UserViewController alloc] init];        
            }
            [self.navigationController pushViewController:self.userViewController 
                                                 animated:YES]; 
            
        } else if (SettingsViewSection0CacheRow == indexPath.row) {
            
            if (!self.cacheViewController) {
                self.cacheViewController = [[CacheViewController alloc] init];        
            }
            [self.navigationController pushViewController:self.cacheViewController 
                                                 animated:YES]; 
        } 
    }
    
    if (2 == indexPath.section) {
        
    }
}

@end
