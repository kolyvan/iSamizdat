//
//  VotedViewController.m
//  iSamizdat
//
//  Created by Kolyvan on 13.06.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/iSamizdat
//  this file is part of iSamizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt
// 

#import "VotedViewController.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "SamLibAgent.h"
#import "SamLibModel.h"
#import "SamLibText.h"
#import "SamLibText+IOS.h"
#import "SamLibAuthor.h"
#import "TextContainerController.h"

@interface VotedViewController () {
    NSArray *_texts;
}
@property (nonatomic, strong) TextContainerController* textContainerController;
@end

@implementation VotedViewController

@synthesize textContainerController;

- (id) init
{
    self =  [self initWithNibName:@"VotedViewController" bundle:nil];
    if (self) {
        self.title = locString(@"Voted");
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemTopRated tag: 2];        
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
    //[self.navigationController setNavigationBarHidden:YES animated:YES];
    [self prepareData];
    [self.tableView reloadData];    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.textContainerController = nil;
    _texts = nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];         
    self.textContainerController = nil;    
}

#pragma mark - private

- (void) prepareData
{
    _texts = nil;
    
    NSMutableArray * ma = [NSMutableArray array];
    
    for (SamLibAuthor *author in [SamLibModel shared].authors)
        for (SamLibText *text in author.texts)            
            if (text.myVote != 0)
                [ma push:text];
    
    if (ma.nonEmpty)
        _texts = [ma copy];
}

+ (UIImage *) mkVoteImage: (NSInteger) number
{
    static NSMutableDictionary *cache;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSMutableDictionary alloc] init];
    });
            
    NSString *text = KxUtils.format(@"%ld", number);
    
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
        [text drawInRect:rect
                withFont:[UIFont boldSystemFontOfSize:20] 
           lineBreakMode:UILineBreakModeTailTruncation 
               alignment:UITextAlignmentCenter];
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();        
        return image;
    }];
}

//- (void) goVote: (id) sender {}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _texts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    SamLibText *text = [_texts objectAtIndex:indexPath.row]; 
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                      reuseIdentifier:CellIdentifier];                
                
        //UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];        
        //button.frame = CGRectMake(0, 0, 24, 24);        
        //[button addTarget:self 
        //           action:@selector(goVote:) 
        // forControlEvents:UIControlEventTouchUpInside];        
        //cell.accessoryView = button;
    }

    cell.textLabel.text = text.title;
    cell.detailTextLabel.text = text.author.name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = [self->isa mkVoteImage: text.myVote];        
    //cell.imageView.image = text.image;        
    
    //UIButton *button = (UIButton *)cell.accessoryView;
    //button.tag = indexPath.row;
    //[button setBackgroundImage:[self->isa mkVoteImage: text.myVote] 
    //                  forState:UIControlStateNormal];
        
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{            
    if (!self.textContainerController) {
        self.textContainerController = [[TextContainerController alloc] init];
    }
    SamLibText *text = [_texts objectAtIndex:indexPath.row];    
    self.textContainerController.text = text;
    self.textContainerController.selectedIndex = TextInfoViewSelected;
    [self.navigationController pushViewController:self.textContainerController 
                                         animated:YES];
    
    //[self.navigationController setNavigationBarHidden:NO animated:YES];    
}


@end
