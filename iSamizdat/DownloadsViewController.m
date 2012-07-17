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
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
//#import "SamLibText+IOS.h"
//#import "UIFont+Kolyvan.h"
#import "SamLibStorage.h"

////

@interface DownloadsViewController () {
    NSMutableArray *_attrs;
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
   
    UIBarButtonItem *backBtn =  [[UIBarButtonItem alloc] initWithTitle: locString(@"Downloads")
                                                                 style:UIBarButtonItemStylePlain
                                                                               target:nil
                                                                               action:nil];
    self.navigationItem.backBarButtonItem = backBtn;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.backBarButtonItem = nil;    
    _attrs = nil;
}

- (void) refreshTitle
{
    unsigned long long totalSize = 0;
    
    for (NSDictionary *attr in _attrs)
        totalSize += [[attr get: @"NSFileSize"] unsignedLongLongValue];
    
    NSString *rank = @"Kb";
    CGFloat totalSizeF = totalSize / 1024.0;
    if (totalSizeF  > 1024.0) {
        rank = @"Mb";
        totalSizeF = totalSizeF / 1024.0;
    }
    
    self.title = KxUtils.format(@"%@ (%.1f %@)", locString(@"Downloads"), totalSizeF, rank);
}

- (NSArray *) prepareData
{
    NSArray *authors = [SamLibModel shared].authors;
    
    NSFileManager *fm =  KxUtils.fileManager();
    
    NSMutableArray *ma = [NSMutableArray array];
    NSMutableArray *attrs = [NSMutableArray array];        
    
    for (SamLibAuthor *author in authors) {
        if (!author.ignored) {
            for (SamLibText *text in author.texts) {            
                if (text.htmlFile.nonEmpty) {
                    [ma push:text];                    
                    NSDictionary *attr = [fm attributesOfItemAtPath: text.htmlFile error: nil];
                    if (!attr) 
                        attr = [NSDictionary dictionary];
                    [attrs push:attr];
                }
            }
        }
    }
        
    _attrs = attrs;    
    [self refreshTitle];
    
    return ma;
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
    
    NSString *s = KxUtils.format(@"%@\n%7.1f Kb   %@", 
                                 text.author.name,
                                 size ? size.unsignedLongLongValue / 1024.0 : -1,
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
