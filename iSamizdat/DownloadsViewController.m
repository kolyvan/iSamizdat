//
//  SavedViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 17.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "DownloadsViewController.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "KxTuple2.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibStorage.h"

////

@interface DownloadsViewController () {
    NSMutableArray *_attrs;
    BOOL _sortByDate;
}
@end

@implementation DownloadsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.title = locString(@"Downloads");
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemDownloads tag: 0]; 
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
   
    UIBarButtonItem *backBtn =  [[UIBarButtonItem alloc] initWithTitle:locString(@"Downloads")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
    self.navigationItem.backBarButtonItem = backBtn;
    
    
    UIBarButtonItem *sortBtn =  [[UIBarButtonItem alloc] initWithTitle:locString(@"by date")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(toggleSort:)];
    
    self.navigationItem.rightBarButtonItem = sortBtn;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.backBarButtonItem = nil;    
    self.navigationItem.rightBarButtonItem = nil;
    _attrs = nil;
    _sortByDate = NO;
}

- (void) toggleSort: (UIBarButtonItem *) button
{
    _sortByDate = !_sortByDate;
    button.title = _sortByDate ? locString(@"by author") : locString(@"by date");
    [self refreshView];
}

- (void) refreshTitle
{
    unsigned long long totalSize = 0;
    
    for (NSDictionary *attr in _attrs)
        totalSize += [[attr get: @"NSFileSize"] unsignedLongLongValue];
    
    NSString *rank = @"Kb";
    totalSize = totalSize / 1024.0;
    if (totalSize  > 1024.0) {
        rank = @"Mb";
        totalSize = floor(totalSize / 1024.0 + .5);
    }
    
    self.navigationItem.title = KxUtils.format(@"%@ (%qu%@)", locString(@"Downloads"), totalSize, rank);
}

- (NSArray *) prepareData
{
    NSArray *authors = [SamLibModel shared].authors;    
    NSFileManager *fm =  KxUtils.fileManager();    
    NSMutableArray *ma = [NSMutableArray array];
        
    for (SamLibAuthor *author in authors) {
        if (!author.ignored) {
            for (SamLibText *text in author.texts) {            
                if (text.htmlFile.nonEmpty) {
                    
                    NSDictionary *attr = [fm attributesOfItemAtPath: text.htmlFile error: nil];
                    if (!attr) 
                        attr = [NSDictionary dictionary];                    
                    [ma push:[KxTuple2 first:text second: attr]];
                }
            }
        }
    }
    
    KxTuple2 *tuple;
    
    if (_sortByDate) {
    
        tuple = [ma sortWith:^(KxTuple2 *l, KxTuple2 *r) {
            
            NSDate *dl = [l.second get:@"NSFileModificationDate"];
            NSDate *dr = [r.second get:@"NSFileModificationDate"]; 
            return [dr compare:dl];
        }].unzip;
        
    } else {
        
        tuple = ma.unzip;
    }
        
    _attrs = [tuple.second mutableCopy];    
    [self refreshTitle];
    
    return tuple.first;
}

- (NSInteger) textContainerSelected
{
    return TextReadViewSelected;
}

- (BOOL) canRemoveText: (SamLibText *) text
{
    return YES;
}

- (void) handleRemoveText: (SamLibText *) text
{
    [text removeTextFiles:YES andComments:YES];    
    NSInteger index = [self.texts indexOfObject:text];    
    [_attrs removeObjectAtIndex:index];    
    [self refreshTitle];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleSubtitle];    
    
    SamLibText *text = [self.texts objectAtIndex:indexPath.row];         
    NSDictionary *attr = [_attrs objectAtIndex:indexPath.row];
    NSNumber *size = [attr get: @"NSFileSize"];
    NSDate *ts = [attr get: @"NSFileModificationDate"];    
    
    NSMutableString *sizeAsStr = [NSMutableString string];    
    [sizeAsStr appendFormat: @"%quKb", size.unsignedLongLongValue / 1024, nil];       
    while (sizeAsStr.length < 9)        
        [sizeAsStr appendString:@" "];    
        
    NSString *s = KxUtils.format(@"%@\n%@ %@", 
                                 text.author.name,                                 
                                 sizeAsStr,
                                 ts ? [ts dateFormatted] : @"?", 
                                 nil);
    
    cell.textLabel.text = text.title;    
    cell.detailTextLabel.text = s;    
    cell.detailTextLabel.numberOfLines = 2;
    cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:14];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

@end
