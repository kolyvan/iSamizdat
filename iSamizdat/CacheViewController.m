//
//  CacheViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 20.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "CacheViewController.h"
#import "KxUtils.h"
#import "KxMacros.h"
#import "SamLibStorage.h"

enum {
    
    CacheViewTextRow,
    CacheViewCommentsRow,    
    CacheViewNamesRow,        
    
    CacheViewNumberOfRows,
};

@interface CacheViewController ()
@end

@implementation CacheViewController

- (id) init
{
    self = [self initWithNibName:@"CacheViewController" bundle:nil];
    if (self) {
        self.title = locString(@"Cache Settings");
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

    //self.navigationItem.rightBarButtonItem = saveButton;
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.leftBarButtonItem = nil;    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) controlEventValueChanged: (id) sender
{
    UISwitch * button = sender;
    switch ([sender tag]) {
        case CacheViewTextRow:      SamLibStorage.setAllowTexts(button.on); break;
        case CacheViewCommentsRow:  SamLibStorage.setAllowComments(button.on); break;
        case CacheViewNamesRow:     SamLibStorage.setAllowNames(button.on); break;
    };        
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return CacheViewNumberOfRows;
}

- (UITableViewCell *) mkSwitchCell
{
    static NSString *CellIdentifier = @"SwitchCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                      reuseIdentifier:CellIdentifier];
        UISwitch * button = [[UISwitch alloc] initWithFrame:CGRectZero]; 
        [button addTarget:self 
                   action:@selector(controlEventValueChanged:) 
         forControlEvents:UIControlEventValueChanged]; 
        cell.accessoryView = button;    
    }        
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    cell = [self mkSwitchCell];
    
    UISwitch *button = (UISwitch *)cell.accessoryView;
    button.tag = indexPath.row;    
    
    if (CacheViewTextRow == indexPath.row) {
        
        cell.textLabel.text = locString(@"Texts");
        cell.detailTextLabel.text = KxUtils.format(@"size: %.1fk", SamLibStorage.sizeOfTexts() / 1024.0); 
        button.on = SamLibStorage.allowTexts();
        
    } else if (CacheViewCommentsRow == indexPath.row) {
        
        cell.textLabel.text = locString(@"Comments");
        cell.detailTextLabel.text = KxUtils.format(@"size: %.1fk", SamLibStorage.sizeOfComments() / 1024.0);         
        button.on = SamLibStorage.allowComments();
        
    } else if (CacheViewNamesRow == indexPath.row) {
        
        cell.textLabel.text = locString(@"Names");
        cell.detailTextLabel.text = KxUtils.format(@"size: %.1fk", SamLibStorage.sizeOfNames() / 1024.0);
        button.on = SamLibStorage.allowNames();    
    } 
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
