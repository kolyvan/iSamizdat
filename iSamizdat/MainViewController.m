//
//  AuthorsViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 28.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "MainViewController.h"
#import "KxMacros.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "NSArray+Kolyvan.h"
#import "KxTuple2.h"

@interface MainViewController () {
    NSInteger _version;
}

@property (nonatomic, strong) NSArray *authors;
@property (nonatomic, strong) NSArray *ignored;

@end

@implementation MainViewController

@synthesize authors = _authors;
@synthesize ignored = _ignored;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = locString(@"Samizdat");
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"emblem-system.png"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self 
                                                                      action:@selector(goSettings)];


    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                               target:self 
                                                                               action:@selector(goAddAuthor)];

    self.navigationItem.leftBarButtonItem = settingsButton;    
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.authors = nil;
    self.ignored = nil;
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) viewWillAppear:(BOOL)animated
{
    [self loadContent];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];        
}

#pragma mark - private functions

- (void) loadContent
{
    SamLibModel *model = [SamLibModel shared];
    
    if (_version != model.version ||
        _authors == nil ||
        _ignored == nil) {
        
        _version = model.version;
        
        NSArray *a = [SamLibModel shared].authors;
        KxTuple2 * result = [a partition:^(id elem) {
            return ((SamLibAuthor *)elem).ignored;
        }];    
        
        self.authors = result.second;
        self.ignored = result.first;    
    }
    
}

- (void) goAddAuthor
{
}

- (void) goSettings
{
}

- (void) refresh
{
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{    
    if (section == 1)
        return locString(@"Authors");
    
    else if (section == 2)
        return locString(@"Ignored");
    
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 1;
    
    else if (section == 1)
        return self.authors.count;
    
    else if (section == 2)
        return self.ignored.count;

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    if (indexPath.section == 0) {
        
        cell.textLabel.text = locString(@"Favorites");
        
    } else if (indexPath.section == 1) {        
        
        SamLibAuthor *author = [self.authors objectAtIndex:indexPath.row];    
        cell.textLabel.text = author.name;
        
    } else  if (indexPath.section == 2) {        
        
        SamLibAuthor *author = [self.ignored objectAtIndex:indexPath.row];    
        cell.textLabel.text = author.name;
    }
    
    return cell;
}


@end
