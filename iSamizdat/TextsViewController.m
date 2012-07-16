//
//  TextsViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 16.07.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//

#import "TextsViewController.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "SamLibAgent.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"
#import "TextContainerController.h"

static UIImage * mkVoteImage(NSInteger number)
{
    static NSMutableDictionary *cache;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSMutableDictionary alloc] init];
    });
    
    NSString *text;
    if (number > 9)
        text = @"X";
    else
        text = KxUtils.format(@"%ld", number);
    
    return [cache get:text orSet:^id{
        
        const float R = 0; 
        const float G = 51.0/255;
        const float B = 102.0/255;
        
        CGSize size = {24,24};
        
        UIGraphicsBeginImageContext(size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGRect rect = CGRectMake(0, 0, size.width, size.height);
        CGContextClipToRect(context, rect);
        
        //[[UIColor lightGrayColor] set];
        [[UIColor clearColor] set];
        UIRectFill(rect);
        
        CGRect circle = CGRectInset(rect, 1.0f, 1.0f);
        CGContextSetRGBStrokeColor(context, R, G, B, 0.5f); 
        //CGContextSetRGBFillColor(context, R, G, B, 0.2f);
        CGContextSetLineWidth(context, 2.0f);
        //CGContextFillEllipseInRect(context, circle);
        CGContextStrokeEllipseInRect(context, circle);
        
        //[[UIColor darkTextColor] set]; 
        [[UIColor colorWithRed:R green:G blue:B alpha:1] set]; 
        rect.origin.x += 1;
        rect.size.width -= 1; 
        [text drawInRect:rect
                withFont:[UIFont boldSystemFontOfSize:20] 
           lineBreakMode:UILineBreakModeTailTruncation 
               alignment:UITextAlignmentCenter];
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();        
        return image;
    }];
}


@interface TextsViewController () {
    NSMutableArray *_favorites;
    NSArray *_voted;    
}
@property (readonly) UITableView *tableView;
@property (nonatomic, strong) TextContainerController *textContainerController;
@end

@implementation TextsViewController
@synthesize tableView = _tableView;
@synthesize textContainerController = _textContainerController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.title = locString(@"Favorites");
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemBookmarks tag: 1]; 
    }
    return self;
}

- (void) loadView
{
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero 
                                              style:UITableViewStylePlain];
    
    self.view = _tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self prepareData];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.textContainerController = nil;
    _favorites = nil;
    _voted = nil;
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

#pragma mark - private

- (void) prepareData
{
    NSArray *authors = [SamLibModel shared].authors;
    
    NSMutableArray *favorited = [NSMutableArray array];
    NSMutableArray *voted = [NSMutableArray array];    

    for (SamLibAuthor *author in authors) {
        if (!author.ignored) {
            for (SamLibText *text in author.texts) {            
                if (text.favorited)
                    [favorited push:text];
                if (text.myVote != 0)
                    [voted push:text];            
            }
        }
    }
    
    _favorites = favorited;    
    _voted = [voted copy]; 
}

- (BOOL) isFavSection: (NSInteger) section
{
    return (section == 0 && _favorites.nonEmpty);
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (_favorites.nonEmpty ? 1 : 0) + (_voted.nonEmpty ? 1 : 0);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{           
    if ([self isFavSection: section])
        return locString(@"");
    
    return locString(@"Voted");;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{   
    if ([self isFavSection: section])
        return _favorites.count;    
    return _voted.count;
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
    cell = [self mkCell: @"Cell" withStyle:UITableViewCellStyleSubtitle];    
        
    if ([self isFavSection: indexPath.section]) {
    
        SamLibText *text = [_favorites objectAtIndex:indexPath.row]; 
        
        cell.textLabel.text = text.title;
        cell.detailTextLabel.text = text.author.name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = text.image;    
        
    } else {
    
        SamLibText *text = [_voted objectAtIndex:indexPath.row]; 
    
        cell.textLabel.text = text.title;
        cell.detailTextLabel.text = text.author.name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = mkVoteImage(text.myVote);        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SamLibText *text;    
    
    if ([self isFavSection: indexPath.section]) {
        
        text = [_favorites objectAtIndex:indexPath.row]; 
    
    } else {
    
        text = [_voted objectAtIndex:indexPath.row]; 
    }
    
    if (!self.textContainerController)
        self.textContainerController = [[TextContainerController alloc] init];    
    self.textContainerController.text = text;
    self.textContainerController.selected = TextInfoViewSelected;    
    [self.navigationController pushViewController:self.textContainerController 
                                         animated:YES];
    
    //[self.tableView deselectRowAtIndexPath:indexPath animated:YES];    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView 
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isFavSection: indexPath.section]) 
        return UITableViewCellEditingStyleDelete;
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isFavSection: indexPath.section]) {
    
        SamLibText *text = [_favorites objectAtIndex:indexPath.row];    
        text.favorited = NO;        
        [_favorites removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                         withRowAnimation:UITableViewRowAnimationAutomatic];   
    }
    
}

@end
