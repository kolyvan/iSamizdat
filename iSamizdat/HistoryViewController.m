//
//  HistoryViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 10.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
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
#import "TextReadViewController.h"
#import "CommentsViewController.h"

@interface HistoryViewController ()
@property (nonatomic, strong) TextReadViewController *textReadViewController;
@property (nonatomic, strong) CommentsViewController *commentsViewController;
@end

@implementation HistoryViewController

@synthesize textReadViewController, commentsViewController;

- (id) init
{
    self =  [self initWithNibName:@"HistoryViewController" bundle:nil];
    if (self) {
        self.title = locString(@"Recent");
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemRecents tag: 4];        
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
    [self.tableView reloadData];
    //[self.navigationController setNavigationBarHidden:YES animated:YES];    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.textReadViewController = nil; 
    self.commentsViewController = nil;    
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
    self.textReadViewController = nil; 
    self.commentsViewController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
        
        UIViewController *viewController;        
    
        if (p.category == SamLibHistoryCategoryText) {
            
            if (!self.textReadViewController)
                self.textReadViewController = [[TextReadViewController alloc] init];    
            self.textReadViewController.text = text;
            viewController = self.textReadViewController;
            
        } else {
            
            if (!self.commentsViewController)
                self.commentsViewController = [[CommentsViewController alloc] init];    
            self.commentsViewController.comments = [text commentsObject:YES];
            viewController = self.commentsViewController;            
        }        
        
        [self.navigationController pushViewController:viewController animated:YES];
        //[self.navigationController setNavigationBarHidden:NO animated:YES]; 
    }
}

@end
