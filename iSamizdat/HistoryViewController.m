//
//  HistoryViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 10.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "HistoryViewController.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibHistory.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"
#import "SamLibAuthor.h"
#import "TextContainerController.h"

@interface HistoryViewController ()
@property (nonatomic, strong) TextContainerController *textContainerController;
@end

@implementation HistoryViewController

@synthesize textContainerController;

- (id) init
{
    self =  [self initWithNibName:@"HistoryViewController" bundle:nil];
    if (self) {
        self.title = locString(@"Recent");
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemRecents tag: 0];        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];    

    UIBarButtonItem *clearBtn =  [[UIBarButtonItem alloc] initWithTitle:locString(@"Clear")
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(goClear)];

    self.navigationItem.rightBarButtonItem = clearBtn;

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.textContainerController = nil; 
    self.navigationItem.rightBarButtonItem = nil;    
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

- (void) goClear
{
    [[SamLibHistory shared] clearAll];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [SamLibHistory shared].history.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                      reuseIdentifier:CellIdentifier]; 
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    NSArray *content = [SamLibHistory shared].history;    
    SamLibHistoryEntry *p = [content objectAtIndex:content.count - indexPath.row - 1];     
    BOOL isText = p.category == SamLibHistoryCategoryText;
    
    cell.textLabel.text = p.title;
    cell.detailTextLabel.text = p.name;    
    cell.imageView.image = [UIImage imageNamed: isText ? @"book" : @"comments"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *content = [SamLibHistory shared].history;    
    SamLibHistoryEntry *p = [content objectAtIndex:content.count - indexPath.row - 1];   
    SamLibText *text = [[SamLibModel shared] findTextByKey:p.key];
    
    if (text) {
        
        BOOL isText = p.category == SamLibHistoryCategoryText;
        
        if (!self.textContainerController)
            self.textContainerController = [[TextContainerController alloc] init];    
        self.textContainerController.text = text;
        self.textContainerController.selected = isText ? TextReadViewSelected : TextCommentsViewSelected;
        
        [self.navigationController pushViewController:self.textContainerController 
                                             animated:YES];
        //[self.navigationController setNavigationBarHidden:NO animated:YES]; 
    }
}

@end
